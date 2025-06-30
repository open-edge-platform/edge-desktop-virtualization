/*
 *  Copyright (C) 2025 Intel Corporation
 *  SPDX-License-Identifier: Apache-2.0
 */
package grpcserver

import (
	"context"
	"errors"
	"io/ioutil"
	"net"
	"os"
	"path/filepath"
	"sync"
	"testing"
	"time"
	"sync/atomic"

	"device-plugin/pkg/resources"

	pluginapi "k8s.io/kubelet/pkg/apis/deviceplugin/v1beta1"

	"google.golang.org/grpc"
	"google.golang.org/grpc/test/bufconn"
)

type mockResource struct {
	socketPath      string
	resourceName    string
	devices         []*pluginapi.Device
	allocResp       []*pluginapi.ContainerAllocateResponse
	ListDevicesFunc func() []*pluginapi.Device
}

func (m *mockResource) GetResourceName() string { return m.resourceName }
func (m *mockResource) GetSocketPath() string   { return m.socketPath }
func (m *mockResource) ListDevices() []*pluginapi.Device {
	if m.ListDevicesFunc != nil {
		return m.ListDevicesFunc()
	}
	if m.devices != nil {
		return m.devices
	}
	return []*pluginapi.Device{{ID: "usb-0", Health: pluginapi.Healthy}}
}
func (m *mockResource) Allocate(_ []string) []*pluginapi.ContainerAllocateResponse {
	if m.allocResp != nil {
		return m.allocResp
	}
	return []*pluginapi.ContainerAllocateResponse{{}}
}

func tempSocket(t *testing.T) string {
	dir, err := ioutil.TempDir("", "dp-test")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	return filepath.Join(dir, "device.sock")
}

const bufSize = 1024 * 1024

func setupBufConnServer(t *testing.T, resource resources.Resource) (*grpc.Server, *bufconn.Listener, pluginapi.DevicePluginClient) {
	lis := bufconn.Listen(bufSize)
	server := grpc.NewServer()
	dps := &DevicePluginServer{server: server, resource: resource}
	pluginapi.RegisterDevicePluginServer(server, dps)
	go func() {
		_ = server.Serve(lis)
	}()
	ctx := context.Background()
	conn, err := grpc.DialContext(ctx, "bufnet",
		grpc.WithContextDialer(func(context.Context, string) (net.Conn, error) { return lis.Dial() }),
		grpc.WithInsecure(),
	)
	if err != nil {
		t.Fatalf("failed to dial bufnet: %v", err)
	}
	client := pluginapi.NewDevicePluginClient(conn)
	return server, lis, client
}

func TestListAndWatch(t *testing.T) {
	resource := &mockResource{
		devices: []*pluginapi.Device{
			{ID: "usb-0", Health: pluginapi.Healthy},
			{ID: "usb-1", Health: pluginapi.Unhealthy},
		},
	}
	server, lis, client := setupBufConnServer(t, resource)
	defer server.Stop()
	defer lis.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	stream, err := client.ListAndWatch(ctx, &pluginapi.Empty{})
	if err != nil {
		t.Fatalf("ListAndWatch failed: %v", err)
	}
	resp, err := stream.Recv()
	if err != nil {
		t.Fatalf("Recv failed: %v", err)
	}
	if len(resp.Devices) != 2 {
		t.Errorf("expected 2 devices, got %d", len(resp.Devices))
	}
	if resp.Devices[0].ID != "usb-0" || resp.Devices[1].ID != "usb-1" {
		t.Errorf("unexpected device IDs: %+v", resp.Devices)
	}
}

func TestAllocate(t *testing.T) {
	expectedPath := "/dev/test"
	resource := &mockResource{
		allocResp: []*pluginapi.ContainerAllocateResponse{
			{Devices: []*pluginapi.DeviceSpec{{HostPath: expectedPath}}},
		},
	}
	server, lis, client := setupBufConnServer(t, resource)
	defer server.Stop()
	defer lis.Close()

	req := &pluginapi.AllocateRequest{
		ContainerRequests: []*pluginapi.ContainerAllocateRequest{
			{DevicesIDs: []string{"usb-0"}},
		},
	}
	resp, err := client.Allocate(context.Background(), req)
	if err != nil {
		t.Fatalf("Allocate failed: %v", err)
	}
	if len(resp.ContainerResponses) != 1 {
		t.Errorf("expected 1 container response, got %d", len(resp.ContainerResponses))
	}
	if len(resp.ContainerResponses[0].Devices) != 1 {
		t.Errorf("expected 1 device, got %d", len(resp.ContainerResponses[0].Devices))
	}
	if resp.ContainerResponses[0].Devices[0].HostPath != expectedPath {
		t.Errorf("expected HostPath %s, got %s", expectedPath, resp.ContainerResponses[0].Devices[0].HostPath)
	}
}

func TestGetDevicePluginOptions(t *testing.T) {
	resource := &mockResource{}
	server, lis, client := setupBufConnServer(t, resource)
	defer server.Stop()
	defer lis.Close()

	resp, err := client.GetDevicePluginOptions(context.Background(), &pluginapi.Empty{})
	if err != nil {
		t.Fatalf("GetDevicePluginOptions failed: %v", err)
	}
	if resp == nil {
		t.Fatalf("expected non-nil response")
	}
}

func TestGetPreferredAllocation(t *testing.T) {
	resource := &mockResource{}
	server, lis, client := setupBufConnServer(t, resource)
	defer server.Stop()
	defer lis.Close()

	req := &pluginapi.PreferredAllocationRequest{}
	resp, err := client.GetPreferredAllocation(context.Background(), req)
	if err != nil {
		t.Fatalf("GetPreferredAllocation failed: %v", err)
	}
	if resp == nil {
		t.Fatalf("expected non-nil response")
	}
}

func TestCleanupSockets(t *testing.T) {
	dir, err := ioutil.TempDir("", "dp-cleanuptest")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(dir)
	socket := filepath.Join(dir, "test.sock")

	// Create a fake socket file
	if err := ioutil.WriteFile(socket, []byte("fake"), 0644); err != nil {
		t.Fatalf("failed to create socket file: %v", err)
	}

	resource := &mockResource{socketPath: socket, resourceName: "test.com/mock"}
	resources := []resources.Resource{resource}

	// Should remove the socket file
	if err := CleanupSockets(resources); err != nil {
		t.Fatalf("CleanupSockets failed: %v", err)
	}
	if _, err := os.Stat(socket); !os.IsNotExist(err) {
		t.Errorf("CleanupSockets did not remove the socket file")
	}

	// Should not fail if file does not exist
	if err := CleanupSockets(resources); err != nil {
		t.Fatalf("CleanupSockets failed on missing file: %v", err)
	}
}

func TestServe_StartsAndHandlesSocketDelete(t *testing.T) {
	socket := tempSocket(t)
	defer os.RemoveAll(filepath.Dir(socket))
	resource := &mockResource{socketPath: socket, resourceName: "test.com/mock"}
	resources := []resources.Resource{resource}

	// Mock RegisterWithKubelet: always succeed
	mockRegister := func(sock, name string) error { return nil }

	var serveErr error
	var wg sync.WaitGroup
	wg.Add(1)
	go func() {
		defer wg.Done()
		serveErr = Serve(resources, mockRegister)
	}()

	// Wait for the socket file to be created
	waitForSocket(t, socket)

	// Simulate kubelet restart by deleting socket file
	os.Remove(socket)

	wg.Wait()

	if serveErr == nil || serveErr.Error() != "socket was deleted, kubelet likely restarted" {
		t.Errorf("Serve did not handle socket deletion as expected, got: %v", serveErr)
	}
}

// Helper to wait for socket file creation
func waitForSocket(t *testing.T, socket string) {
	timeout := time.After(5 * time.Second)
	for {
		select {
		case <-timeout:
			t.Fatalf("timeout waiting for socket file: %s", socket)
		default:
			if _, err := os.Stat(socket); err == nil {
				return
			}
			time.Sleep(100 * time.Millisecond)
		}
	}
}

func TestStartDevicePlugin_RestartsOnServeError(t *testing.T) {
	socket := tempSocket(t)
	defer os.RemoveAll(filepath.Dir(socket))
	resource := &mockResource{socketPath: socket, resourceName: "test.com/mock"}

	var callCount int32 // Use atomic counter
	mockServe := func(res []resources.Resource, reg func(string, string) error) error {
		atomic.AddInt32(&callCount, 1) 
		if atomic.LoadInt32(&callCount) == 1 {
			return errors.New("simulated error")
		}
		// On second call, simulate success
		return nil
	}
	mockRegister := func(sock, name string) error { return nil }

	done := make(chan struct{})
	go func() {
		StartDevicePlugin([]resources.Resource{resource}, mockServe, mockRegister)
		close(done)
	}()
	time.Sleep(11 * time.Second)
	if atomic.LoadInt32(&callCount) < 2 { 
		t.Errorf("StartDevicePlugin did not restart Serve as expected, callCount=%d", callCount)
	}
}

func TestMonitorSocket_NotifyOnDelete(t *testing.T) {
	dir, err := ioutil.TempDir("", "dp-monitorsocket")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(dir)
	socket := filepath.Join(dir, "test.sock")
	// Create the file to simulate socket
	f, err := os.Create(socket)
	if err != nil {
		t.Fatalf("failed to create socket file: %v", err)
	}
	f.Close()

	notify := make(chan bool, 1)
	go monitorSocket(socket, notify)

	// Remove the file to trigger notification
	time.Sleep(100 * time.Millisecond)
	os.Remove(socket)

	select {
	case <-notify:
		// Success
	case <-time.After(2 * time.Second):
		t.Fatal("monitorSocket did not notify on socket deletion")
	}
}

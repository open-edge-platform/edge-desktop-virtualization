/*
 *  Copyright (C) 2025 Intel Corporation
 *  SPDX-License-Identifier: Apache-2.0
 */
package grpcserver

import (
	"context"
	"device-plugin/pkg/resources"
	"fmt"
	"log"
	"net"
	"os"
	"path/filepath"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	pluginapi "k8s.io/kubelet/pkg/apis/deviceplugin/v1beta1"
)

type DevicePluginServer struct {
	pluginapi.UnimplementedDevicePluginServer
	server   *grpc.Server
	resource resources.Resource
}

// GetDevicePluginOptions provides plugin options (empty response is fine)
func (s *DevicePluginServer) GetDevicePluginOptions(ctx context.Context, req *pluginapi.Empty) (*pluginapi.DevicePluginOptions, error) {
	return &pluginapi.DevicePluginOptions{}, nil
}

// GetPreferredAllocation is optional (returns empty response)
func (s *DevicePluginServer) GetPreferredAllocation(ctx context.Context, req *pluginapi.PreferredAllocationRequest) (*pluginapi.PreferredAllocationResponse, error) {
	return &pluginapi.PreferredAllocationResponse{}, nil
}

// ListAndWatch streams available devices to Kubelet
func (s *DevicePluginServer) ListAndWatch(req *pluginapi.Empty, stream pluginapi.DevicePlugin_ListAndWatchServer) error {
	if err := stream.Send(&pluginapi.ListAndWatchResponse{Devices: s.resource.ListDevices()}); err != nil {
		return fmt.Errorf("failed to send initial device list: %v", err)
	}

	ticker := time.NewTicker(20 * time.Second)
	defer ticker.Stop()

	done := make(chan bool)
	defer close(done)

	go func() {
		<-stream.Context().Done()
		log.Printf("Stream context done, kubelet may have restarted")
		done <- true
	}()

	for {
		select {
		case <-ticker.C:
			devices := s.resource.ListDevices()

			if err := stream.Send(&pluginapi.ListAndWatchResponse{Devices: devices}); err != nil {
				return fmt.Errorf("failed to send device update: %v", err)
			}

		case <-done:
			log.Printf("ListAndWatch stream context canceled")
			return nil
		}
	}
}

// Allocate handles resource allocation requests from Kubernetes
func (s *DevicePluginServer) Allocate(ctx context.Context, req *pluginapi.AllocateRequest) (*pluginapi.AllocateResponse, error) {
	var responses []*pluginapi.ContainerAllocateResponse
	res := s.resource.Allocate(req.ContainerRequests[0].DevicesIds)
	responses = append(responses, res...)

	return &pluginapi.AllocateResponse{ContainerResponses: responses}, nil
}

// RegisterWithKubelet registers the resource with kubelet
func RegisterWithKubelet(socket string, resourceName string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	conn, err := grpc.DialContext(ctx, pluginapi.KubeletSocket, grpc.WithTransportCredentials(insecure.NewCredentials()), grpc.WithContextDialer(func(ctx context.Context, addr string) (net.Conn, error) {
		d := &net.Dialer{}
		return d.DialContext(ctx, "unix", addr)
	}))
	if err != nil {
		return err
	}
	defer conn.Close()
	log.Printf("connection created for %v", resourceName)
	client := pluginapi.NewRegistrationClient(conn)
	log.Printf("client created for %v", resourceName)
	_, err = client.Register(ctx, &pluginapi.RegisterRequest{
		Version:      pluginapi.Version,
		Endpoint:     filepath.Base(socket),
		ResourceName: resourceName,
	})
	return err
}

// CleanupSockets removes existing socket files if it exists
func CleanupSockets(res []resources.Resource) error {
	for _, resource := range res {
		socket := resource.GetSocketPath()
		if _, err := os.Stat(socket); err == nil {
			if err := os.Remove(socket); err != nil {
				return err
			}
		}
	}
	return nil
}

// StartDevicePlugin starts servers with restart capability
func StartDevicePlugin(
	res []resources.Resource,
	serveFunc func([]resources.Resource, func(string, string) error) error,
	registerFunc func(string, string) error,
) {
	for {
		if err := serveFunc(res, registerFunc); err != nil {
			log.Printf("Device plugin server failed: %v", err)
		}

		time.Sleep(10 * time.Second)

		log.Printf("Restarting device plugin")
	}
}

// Serve starts the gRPC server for each of the resources
func Serve(
	resources []resources.Resource,
	registerFunc func(string, string) error,
) error {
	// Cleanup any existing socket file before binding
	if err := CleanupSockets(resources); err != nil {
		log.Fatalf("Failed to remove existing socket file: %v", err)
	}

	// Detect kubelet restarts
	socketWatcher := make(chan bool)
	// Catch grpc server errors
	errChan := make(chan error, 1)

	for _, resource := range resources {
		dpi := &DevicePluginServer{
			server:   grpc.NewServer(),
			resource: resource,
		}
		pluginapi.RegisterDevicePluginServer(dpi.server, dpi)

		log.Printf("Device plugin server starting for %v\n", dpi.resource.GetResourceName())

		lis, err := net.Listen("unix", resource.GetSocketPath())
		if err != nil {
			return err
		}

		go func() {
			if err := dpi.server.Serve(lis); err != nil {
				errChan <- err
			}
		}()

		// Wait for server to start
		time.Sleep(2 * time.Second)

		// Register resource
		log.Printf("registering with kubelet for %v\n", resource.GetResourceName())
		if err = registerFunc(resource.GetSocketPath(), resource.GetResourceName()); err != nil {
			dpi.server.Stop()
			return fmt.Errorf("failed to register resource %s with Kubelet: %v", resource.GetResourceName(), err)
		}

		go monitorSocket(resource.GetSocketPath(), socketWatcher)
	}

	// Wait for server error, socket deletion, or signal
	select {
	case err := <-errChan:
		return fmt.Errorf("gRPC server error: %v", err)
	case <-socketWatcher:
		return fmt.Errorf("socket was deleted, kubelet likely restarted")
	}
}

// monitorSocket monitors socket file for deletion (indicates kubelet restart)
func monitorSocket(socket string, notify chan<- bool) {
	for {
		if _, err := os.Stat(socket); os.IsNotExist(err) {
			log.Printf("Socket file %s was deleted", socket)
			notify <- true
			return
		}
		time.Sleep(1 * time.Second)
	}
}

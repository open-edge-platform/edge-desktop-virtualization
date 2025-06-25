/*
 *  Copyright (C) 2025 Intel Corporation
 *  SPDX-License-Identifier: Apache-2.0
 */
package resources

import (
	"device-plugin/pkg/constants"
	"fmt"
	"log"
	"os"

	pluginapi "k8s.io/kubelet/pkg/apis/deviceplugin/v1beta1"
)

type ResourceIGPU struct{}

// GetResourceName returns the resource name for registration
func (r *ResourceIGPU) GetResourceName() string {
	return constants.IGpuResourceName
}

// GetSocketPath returns the socket path for iGPU
func (r *ResourceIGPU) GetSocketPath() string { return constants.IGpuSocketPath }

// ListDevices returns available igpu devices
func (r *ResourceIGPU) ListDevices() []*pluginapi.Device {
	// Check if mount path exists and then allocate.
	if _, err := os.Stat(constants.IGpuDevicePath); os.IsNotExist(err) {
		return []*pluginapi.Device{} // Return an empty list if the path doesn't exist
	}
	if _, err := os.Stat(constants.RenderD128DevicePath); os.IsNotExist(err) {
		return []*pluginapi.Device{} // Return an empty list if the path doesn't exist
	}
	devices := make([]*pluginapi.Device, constants.IGpuDeviceCount)

	for i := 0; i < constants.IGpuDeviceCount; i++ {
		devices[i] = &pluginapi.Device{
			ID:     fmt.Sprintf("%s-%d", constants.IGpuDevicePrefix, i),
			Health: pluginapi.Healthy,
		}
	}
	return devices
}

// Allocate provides the required devices for igpu
func (r *ResourceIGPU) Allocate(deviceIDs []string) []*pluginapi.ContainerAllocateResponse {
	log.Printf("igpu deviceIds - %v\n", deviceIDs)
	return []*pluginapi.ContainerAllocateResponse{
		{
			Devices: []*pluginapi.DeviceSpec{
				{
					HostPath:      constants.IGpuDevicePath,
					ContainerPath: constants.IGpuDevicePath,
					Permissions:   constants.Permissions,
				},
				{
					HostPath:      constants.RenderD128DevicePath,
					ContainerPath: constants.RenderD128DevicePath,
					Permissions:   constants.Permissions,
				},
			},
		},
	}
}

#!/bin/bash

info "disabling md raid autoassembly for clusterboot"
udevproperty rd_NO_MD=1


#!/usr/bin/env bash
# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# @file: lib/components/components.sh
# @brief: Component management utilities for modular system installation.
# @author: Andrew Vasilyev
# @license: MIT
#
if [[ -n "${_LIB_CORE_COMPONENTS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_COMPONENTS_SOURCED=1

source "${MEOW}/lib/components/core.sh"
source "${MEOW}/lib/components/packages.sh"
source "${MEOW}/lib/components/repository.sh"
source "${MEOW}/lib/components/dependencies.sh"
source "${MEOW}/lib/components/symlinks.sh"
source "${MEOW}/lib/components/operations.sh"

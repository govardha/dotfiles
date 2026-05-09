#!/usr/bin/env bash
# DEPRECATED: PreToolUse hooks cannot mutate tool inputs.
# Kiro CLI hooks only support allow (exit 0) or block (exit 2).
# The KIRO_CLI=1 env var is now exported in bashrc.common instead.
#
# This file is kept for reference only.
exit 0

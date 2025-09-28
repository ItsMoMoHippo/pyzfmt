const std = @import("std");

pub const FmtError = FileErr || ArgCountErr;

pub const ArgCountErr = error{ FileArgMissing, ExtraArgs };

pub const FileErr = error{ FileNotFound, PermissionDenied, InvalidFileType };

const std = @import("std");

pub const FooErr = FileErr || ArgCountErr;
pub const ArgCountErr = error{ FileArgMissing, ExtraArgs };
pub const FileErr = error{ FileNotFound, PermissionDenied, InvalidFileType };

pub const AppErr = error{ TSError, InvalidFT, Help };

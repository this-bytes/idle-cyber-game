-- Compatibility shim: legacy 'src.systems.upgrade_system' -> modern 'src.core.security_upgrades'
local ok, su = pcall(require, 'src.core.security_upgrades')
if not ok then
    su = require('security_upgrades')
end
return su

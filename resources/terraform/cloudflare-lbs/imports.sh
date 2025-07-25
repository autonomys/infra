#!/bin/bash
# This script imports Cloudflare Load Balancer resources into Terraform state.

# Import RPC Mainnet Health Check
terraform import cloudflare_load_balancer_monitor.rpc_mainnet_health_check a0c2610e19310a13e355eb50fe041a97/80e2b143f1b4553b05c54f5de582427d

# Import RPC Taurus Health Check
terraform import cloudflare_load_balancer_monitor.rpc_taurus_health_check a0c2610e19310a13e355eb50fe041a97/d4169f7b3fe896287bc127191c03bd62

# Import RPC Taurus EVM Health Check
terraform import cloudflare_load_balancer_monitor.rpc_taurus_evm_health_check a0c2610e19310a13e355eb50fe041a97/c22a1414ec304fb46d37f95bac2b731a

# Import Mainnet-RPC pool
terraform import cloudflare_load_balancer_pool.mainnet_rpc a0c2610e19310a13e355eb50fe041a97/0e3fdc24211b5a232023db3fc68002bd

# Import Taurus-RPC pool
terraform import cloudflare_load_balancer_pool.taurus_rpc a0c2610e19310a13e355eb50fe041a97/488cd954504a0285f6e347417363062f

# Import Taurus-RPC-EVM pool
terraform import cloudflare_load_balancer_pool.taurus_rpc_evm a0c2610e19310a13e355eb50fe041a97/004df046e23db27f92a16ccb9cc50e30

# Import Taurus-RPC-EVM-Fallback pool
terraform import cloudflare_load_balancer_pool.taurus_rpc_evm_fallback a0c2610e19310a13e355eb50fe041a97/ff295017c1ab46525b24fcde5b00eed1

# Import auto-evm-lb.taurus.autonomys.xyz
terraform import cloudflare_load_balancer.auto_evm_lb_taurus c2b6ccca486f046dac214ee6eaa8295a/4a7e075cae7abf7e9d70d6e27abccac1

# Import rpc-lb.mainnet.autonomys.xyz
terraform import cloudflare_load_balancer.rpc_lb_mainnet c2b6ccca486f046dac214ee6eaa8295a/f38ef4ef1fc28508c2004f9756635ea1

# Import rpc-lb.taurus.autonomys.xyz
terraform import cloudflare_load_balancer.rpc_lb_taurus c2b6ccca486f046dac214ee6eaa8295a/0babbfbb55a1a2f18dcc15cd66554f5c

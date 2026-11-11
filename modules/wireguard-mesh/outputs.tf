output "mesh_id" {
  description = "Changes whenever the mesh config is re-applied"
  value       = null_resource.mesh.id
}

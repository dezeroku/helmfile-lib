output "entity_id" {
  description = "Vault identity entity of the user. Needed to add them to a group managed by another state."
  value       = vault_identity_entity.user.id
}

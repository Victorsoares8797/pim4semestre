/// Regras compartilhadas pelas telas e pelo repositório de demonstração.
bool isValidEmail(String email) {
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim());
}

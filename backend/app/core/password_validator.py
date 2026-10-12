import re

COMMON_WEAK_PASSWORDS = {
    "password", "password123", "admin123", "hostel123", "welcome123",
    "12345678", "qwerty123", "letmein123", "student123", "changeme",
}

class PasswordValidationError(ValueError):
    pass

def validate_password_strength(password: str) -> str:
    """
    Validates password against OWASP ASVS rules:
    - Minimum 8 characters (maximum 128 to prevent computational DoS)
    - At least 1 uppercase letter
    - At least 1 lowercase letter
    - At least 1 digit
    - At least 1 special character
    - Not in common weak passwords dictionary
    """
    if not password or len(password) < 8:
        raise PasswordValidationError("Password must be at least 8 characters long.")
    if len(password) > 128:
        raise PasswordValidationError("Password must not exceed 128 characters.")
    if password.lower() in COMMON_WEAK_PASSWORDS:
        raise PasswordValidationError("Password is too common and easily guessable.")
    if not re.search(r"[A-Z]", password):
        raise PasswordValidationError("Password must contain at least one uppercase letter.")
    if not re.search(r"[a-z]", password):
        raise PasswordValidationError("Password must contain at least one lowercase letter.")
    if not re.search(r"\d", password):
        raise PasswordValidationError("Password must contain at least one number.")
    if not re.search(r"[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]", password):
        raise PasswordValidationError("Password must contain at least one special character (!@#$%^&*()_+-=[]{}|;:,.<>?).")
    
    return password

def title_case(text):
    """Capitalise the first letter of every space-separated word and lowercase the rest."""
    return " ".join(word.capitalize() for word in text.split(" "))

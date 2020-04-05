class Enum:
    def __init__(self):


    def initializeValues(self):
        # This should be overridden by the implementing class
        return []

    def values(self):
        pass

class EnumValue:
    def ordinal(self):
        pass

    def name(self):
        pass
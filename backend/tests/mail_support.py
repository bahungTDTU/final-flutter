class RecordingDelivery:
    """Explicit test double, never selected by application environment."""
    mode = 'test_only'

    def __init__(self):
        self.messages = []
        self.fail = False

    def send(self, recipient, kind, token):
        if self.fail:
            return 'delivery_failed'
        self.messages.append({'recipient': recipient, 'kind': kind, 'token': token})
        return 'test_only'

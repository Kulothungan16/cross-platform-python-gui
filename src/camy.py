import time

from kivy.lang import Builder
from kivy.utils import platform
from kivymd.uix.dialog import BaseDialog


Builder.load_string(
    """

<Camy>
    on_pre_open: cam.play = True
    on_dismiss: cam.play = False
    auto_dismiss: False

    MDBoxLayout:
        orientation: 'vertical'
        md_bg_color: root.theme_cls.bg_normal

        Camera:
            id: cam
            resolution: self.width, self.height

        MDBoxLayout:
            size_hint_y: None
            height: root.theme_cls.standard_increment

            Widget:

            MDIconButton:
                icon: 'camera-iris'
                pos_hint: {'center_y': .5}
                on_release: root.capture_image()

            Widget:

    AnchorLayout:
        anchor_x: 'left'
        anchor_y: 'top'

        MDIconButton:
            icon: 'arrow-left'
            on_release: root.dismiss()

"""
)


class Camy(BaseDialog):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.register_event_type("on_picture_taken")

    def capture_image(self):
        timestr = time.strftime("%Y%m%d_%H%M%S")
        path = f"IMG_{timestr}.png"
        self.ids.cam.export_to_png(path)
        print(path)
        self.dispatch("on_picture_taken")

    def on_picture_taken(self, *args):
        pass

# this is needed for supporting Windows 10 with OpenGL < v2.0
# Example: VirtualBox w/ OpenGL v1.1
from kivy.lang import Builder
from kivy.utils import platform
from kivymd.app import MDApp

from camy import Camy

if platform == 'win32':
    os.environ['KIVY_GL_BACKEND'] = 'angle_sdl2'


KV = """
BoxLayout:
    Button:
        text: 'Open'
        on_release: app.open()
    MDLabel:
        id: lbl
        halign: 'center'
"""


class MainApp(MDApp):
    def build(self):
        self.root = Builder.load_string(KV)

    def on_pic(self, *args):
        try:
            self.root.ids.lbl.text = str(args)
        except Exception as e:
            self.root.ids.lbl.text = str(e)

    def on_start(self):
        try:
            self.cam = Camy()
            self.cam.bind(on_picture_taken=self.on_pic)
        except Exception as e:
            self.root.ids.lbl.text = str(e)

    def open(self):
        try:
            self.cam.open()
        except Exception as e:
            self.root.ids.lbl.text = str(e)


MainApp().run()


"""Generate the app's small native vector mark (requires Pillow for regeneration)."""
import json
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
scale = 3
image = Image.new('RGB', (1024*scale, 1024*scale), '#F7F3EA')
draw = ImageDraw.Draw(image)
def ellipse(bounds, fill):
    draw.ellipse(tuple(int(x*scale) for x in bounds), fill=fill)
ellipse((395, 170, 815, 590), '#F4D5B5')
ellipse((449, 224, 761, 536), '#EBC38D')
ellipse((-200, 565, 850, 1700), '#D9E2CE')
ellipse((120, 635, 1340, 1600), '#B9C8AB')
ellipse((620, 785, 1480, 1460), '#839A77')
ellipse((200, 350, 390, 540), '#FFFDF8')
ellipse((285, 285, 500, 500), '#FFFDF8')
draw.rounded_rectangle(tuple(int(x*scale) for x in (200, 415, 550, 540)), radius=60*scale, fill='#FFFDF8')
image = image.resize((1024,1024), Image.Resampling.LANCZOS)
icons = root/'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for entry in json.loads((icons/'Contents.json').read_text())['images']:
    size = round(float(entry['size'].split('x')[0])*float(entry['scale'][:-1]))
    image.resize((size,size), Image.Resampling.LANCZOS).save(icons/entry['filename'])
for size in (192,512):
    for name in (f'Icon-{size}.png',f'Icon-maskable-{size}.png'):
        image.resize((size,size),Image.Resampling.LANCZOS).save(root/'web/icons'/name)
image.resize((32,32),Image.Resampling.LANCZOS).save(root/'web/favicon.png')
# Launch images have transparent padding, so the system background remains visible.
for factor, suffix in [(1,''),(2,'@2x'),(3,'@3x')]:
    logo = Image.new('RGBA',(168*factor,185*factor),(0,0,0,0))
    mark = image.resize((100*factor,100*factor),Image.Resampling.LANCZOS)
    logo.paste(mark,(34*factor,42*factor))
    logo.save(root/f'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{suffix}.png')

from art import *

ANIMALS = {"Frog": frog, "Duck": duck, "Bee": bee, "Owl": owl, "Dog": dog, "Fish": fish,
           "Butterfly": butterfly_icon, "Flower": flower, "Moon": moon, "Star": star}
for name, fn in ANIMALS.items():
    write(f"Assets/Images/Animals/{name}.svg", svg(256, 256, fn()))

TOYS = {"Ball": ball, "Teddy": teddy, "Blocks": blocks, "ToyCar": toy_car, "Basket": basket, "ToyBox": toy_box}
for name, fn in TOYS.items():
    write(f"Assets/Images/Toys/{name}.svg", svg(256, 256, fn()))

# Profile avatars: animal on a coloured circle badge.
AVATARS = {"Frog": ("#c8f0c0", frog), "Duck": ("#fff1b8", duck), "Bee": ("#ffe0b3", bee),
           "Owl": ("#e6d5f5", owl), "Dog": ("#ffd6cc", dog), "Fish": ("#cce8ff", fish)}
for name, (bg, fn) in AVATARS.items():
    write(f"Assets/Images/Avatars/{name}.svg", svg(256, 256,
          f'<circle cx="128" cy="128" r="124" fill="{bg}"/>' + place(fn(), 34, 34, 188)))
print("ok")

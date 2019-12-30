size = nil
world = {}
active = false

cols = 16
rows = 11
z = 0

scale = 0.1

-- improved Perlin noise
-- https://mrl.nyu.edu/~perlin/noise

permutation = {
    151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225,
    140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247,
    120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32, 57, 177,
    33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165,
    71, 134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122, 60, 211,
    133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54, 65, 25,
    63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169, 200, 196,
    135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217,
    226, 250, 124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212, 207, 206,
    59, 227, 47, 16, 58, 17, 182, 189, 28, 42, 223, 183, 170, 213, 119, 248,
    152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9, 129, 22,
    39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104, 218,
    246, 97, 228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241,
    81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214, 31, 181, 199, 106, 157,
    184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236, 205, 93,
    222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180
}

p = {}
for i = 0, 255 do
    p[i] = permutation[i + 1]
    p[256 + i] = permutation[i + 1]
end

function fade(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end

function lerp(t, a, b)
    return a + t * (b - a)
end

function grad(hash, x, y, z)
    local h, u, v
    h = hash % 16
    u = h < 8 and x or y
    v = h < 4 and y or (h == 12 or h == 14) and x or z;
    return ((h % 2) == 0 and u or -u) + ((h % 4) == 0 and v or -v)
end

function noise(x, y, z)
    local X, Y, Z, u, v, w, A, AA, AB, B, BA, BB

    X = math.floor(x) % 255
    Y = math.floor(y) % 255
    Z = math.floor(z) % 255

    x = x - math.floor(x)
    y = y - math.floor(y)
    z = z - math.floor(z)

    u = fade(x)
    v = fade(y)
    w = fade(z)

    A = p[X] + Y
    AA = p[A] + Z
    AB = p[A+1] + Z
    B = p[X+1] + Y
    BA = p[B] + Z
    BB = p[B+1] + Z

    return lerp(w, lerp(v, lerp(u, grad(p[AA  ], x  , y  , z   ),
                                   grad(p[BA  ], x-1, y  , z   )),
                           lerp(u, grad(p[AB  ], x  , y-1, z   ),
                                   grad(p[BB  ], x-1, y-1, z   ))),
                   lerp(v, lerp(u, grad(p[AA+1], x  , y  , z-1 ),
                                   grad(p[BA+1], x-1, y  , z-1 )),
                           lerp(u, grad(p[AB+1], x  , y-1, z-1 ),
                                   grad(p[BB+1], x-1, y-1, z-1 ))))
end

-- HSV to RGB conversion
-- https://en.wikipedia.org/wiki/HSL_and_HSV#HSV_to_RGB_alternative

function hsv2rgb(h, s, v)
    local f = function(n)
        local k = (n + h * 6) % 6
        return math.floor(255 * (v - v * s * math.max(math.min(k, 4 - k, 1), 0)))
    end
    return {f(5), f(3), f(1)}
end

-- event handling

function init()
    local c, r
    for c = 0, cols - 1 do
        for r = 0, rows - 1 do
            world[c * rows + r] = {0, 0, 0}
        end
    end
end

function update()
    local c, r, h, s, v
    z = z + 1
    for c = 0, cols - 1 do
        for r = 0, rows - 1 do
            h = noise(c * scale, r * scale, z * scale * 0.9) * 0.9 + 0.1
            s = noise(c * scale, r * scale, z * scale * 1.0) * 0.5 + 0.5
            v = noise(c * scale, r * scale, z * scale * 1.1) * 0.1 + 0.9
            world[c * rows + r] = hsv2rgb(h, s, v)
        end
    end
end

function on.construction()
    init()
    timer.start(0.2)
end

function on.activate() active = true end
function on.deactivate() active = false end

function on.timer()
    if active then
        update()
        platform.window.invalidate()
    end
end

function on.resize(w, h)
    size = {w, h}
    platform.window.invalidate()
end


function on.paint(gc)
    local w, h, c, r, rgb

    w = math.floor(size[1] / 19)
    w = math.min(cols, w)
    h = math.floor(size[2] / 19)
    h = math.min(rows, h)

    gc:setColorRGB(0, 0, 0)
    gc:fillRect(0, 0, size[1], size[2])

    for c = 0, w - 1 do
        for r = 0, h - 1 do
            rgb = world[c * rows + r]
            gc:setColorRGB(unpack(rgb))
            gc:fillRect(7 + c * 19, 2 + r * 19, 19, 19)
        end
    end
end

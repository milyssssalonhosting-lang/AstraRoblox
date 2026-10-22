"""Slime al Espacio — cinco mallas originales, Prompt 14.

Blender 4.3+: blender -b -t 2 --python-exit-code 1 --python build_rockets.py -- --output-dir ./salida
Construye, exporta FBX, reimporta, valida y renderiza cada FBX exportado.
Sin dependencias externas: bpy, mathutils y numpy incluidos con Blender.
Las coordenadas de diseño/documentación son X derecha, Y arriba, frente -Z.
En Blender se convierten a su espacio nativo Z arriba antes de exportar a FBX Y arriba.
No contiene keyframes, código de juego, descargas ni acceso a la red.
"""

import argparse
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy
import bmesh
import numpy as np
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree


ROOT = Path(__file__).resolve().parent
PARSER = argparse.ArgumentParser(description=__doc__)
PARSER.add_argument('--output-dir', type=Path, default=ROOT)
PARSER.add_argument('--only', choices=['comun', 'raro', 'epico', 'legendario', 'mitico'])
PARSER.add_argument('--skip-render', action='store_true')
PARSER.add_argument('--verify-only', action='store_true')
ARGS = PARSER.parse_args(sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else [])
OUT = ARGS.output_dir.resolve()
OUT.mkdir(parents=True, exist_ok=True)

# Diseño Y-up -> Blender Z-up. Su inversa recupera los metros documentados.
C = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))
CI = C.inverted()
PROFILE = [(-1.12, .32), (-1.07, .40), (-.92, .49), (-.65, .56),
           (-.28, .594), (.12, .60), (.48, .555), (.79, .45),
           (1.05, .31), (1.26, .16), (1.36, .065), (1.40, 0)]
BODY_RECT = (16, 16, 752, 1008)
FIN_RECT = (784, 16, 1008, 240)
GLASS_RECT = (784, 272, 1008, 496)
SWATCHES = ['white', 'nose', 'fin', 'edge', 'silver', 'blue', 'dark', 'gold',
            'cyan', 'orange', 'pink', 'violet', 'teal', 'bright', 'light', 'black']
BASE = dict(white='#F7FBFF', silver='#B7C5D7', blue='#075AF5', dark='#34425E',
            gold='#FFD43B', cyan='#39C7FA', orange='#FF7A24', pink='#EF54D9',
            violet='#833CE5', teal='#078C79', bright='#FFFFFF', light='#69E9FF', black='#1C1628')
SPECS = {
    'comun': dict(name='Burbuja', title='Común', body='#F7FBFF', nose='#1648F5',
                  fin='#1648F5', edge='#0B2794', fire=['#FFD951', '#FF963C']),
    'raro': dict(name='Turbo', title='Raro', body='#F7FBFF', nose='#078C79',
                 fin='#30DFAD', edge='#057D70', fire=['#66FFE3', '#25CFF4']),
    'epico': dict(name='Relámpago', title='Épico', body='#833CE5', nose='#FFE34D',
                  fin='#FFE34D', edge='#D79519', fire=['#FFF477', '#B05CFF']),
    'legendario': dict(name='Fénix', title='Legendario', body='#FFC83D', nose='#FF7A24',
                       fin='#FF7A24', edge='#FFE58A', fire=['#C7FAFF', '#26CFFF', '#2D6BFF']),
    'mitico': dict(name='Galáctico', title='Mítico', body='#5630B7', nose='#6931D8',
                   fin='#B889FF', edge='#43CAFF',
                   fire=['#FF516B', '#FFAE43', '#FFE45C', '#69EF8B', '#43D9FF', '#4777FF', '#B16AFF']),
}


def rgb(value):
    return np.array([int(value[i:i + 2], 16) / 255 for i in (1, 3, 5)], dtype=np.float32)


def palette(key):
    return dict(BASE, **{k: SPECS[key][k] for k in ('nose', 'fin', 'edge')})


def radius_at(y):
    return np.interp(y, [p[0] for p in PROFILE], [p[1] for p in PROFILE])


def poly_mask(x, y, points):
    inside = np.zeros(np.broadcast_shapes(x.shape, y.shape), dtype=bool)
    for i, (ax, ay) in enumerate(points):
        bx, by = points[i - 1]
        inside ^= ((ay > y) != (by > y)) & (x < (bx - ax) * (y - ay) / (by - ay + 1e-12) + ax)
    return inside


def star(cx, cy, r, n=5):
    return [(cx + math.cos(math.pi / 2 + k * math.pi / n) * r * (1 if k % 2 == 0 else .46),
             cy + math.sin(math.pi / 2 + k * math.pi / n) * r * (1 if k % 2 == 0 else .46))
            for k in range(n * 2)]


def smooth_contour(points, steps=2):
    """Catmull-Rom cerrado; pocas muestras, suavidad sin subdivisión costosa."""
    result = []
    for i in range(len(points)):
        a, b, c, d = (np.array(points[(i + k) % len(points)], dtype=float) for k in (-1, 0, 1, 2))
        for j in range(steps):
            t = j / steps
            v = .5 * ((2*b) + (-a+c)*t + (2*a-5*b+4*c-d)*t*t + (-a+3*b-3*c+d)*t*t*t)
            result.append(tuple(v))
    return result


NORMAL_FIN = smooth_contour([(.44, -.39), (.68, -.47), (.91, -.82),
                             (1.015, -1.17), (.98, -1.27), (.82, -1.10),
                             (.63, -.99), (.43, -1.08)])
FAST_FIN = smooth_contour([(.44, -.39), (.73, -.51), (1.06, -1.15),
                           (1.02, -1.25), (.83, -1.09), (.62, -.98), (.43, -1.08)])
def bezier_contour(start,segments,steps=4):
    result=[];a=np.array(start,dtype=float)
    for controls in segments:
        b,c,d=(np.array(p,dtype=float) for p in controls)
        for i in range(steps):
            t=i/steps
            result.append(tuple((1-t)**3*a+3*(1-t)**2*t*b+3*(1-t)*t*t*c+t**3*d))
        a=d
    return result


WING = bezier_contour((.44,-.40),[
    ((.62,-.40),(.85,-.30),(.96,-.20)),
    ((1.075,-.105),(1.12,-.35),(.91,-.58)),
    ((1.05,-.48),(1.15,-.45),(1.15,-.58)),
    ((1.16,-.74),(1.02,-.81),(.90,-.89)),
    ((1.08,-.79),(1.14,-.83),(1.08,-.97)),
    ((1.02,-1.11),(.89,-1.16),(.80,-1.23)),
    ((.75,-1.29),(.69,-1.14),(.60,-1.06)),
    ((.55,-1.03),(.48,-1.05),(.43,-1.06)),
    ((.43,-.86),(.44,-.62),(.44,-.40)),
])


def make_atlas(key):
    spec, colors = SPECS[key], palette(key)
    pixels = np.ones((1024, 1024, 4), dtype=np.float32)
    pixels[:, :, :3] = rgb('#D8D9E3')
    x0, y0, x1, y1 = BODY_RECT
    h, w = y1-y0, x1-x0
    u = np.linspace(0, 1, w)[None, :]
    v = np.linspace(0, 1, h)[:, None]
    theta = (u - .5) * 2 * math.pi
    y = -1.12 + v * 2.52
    # Coordenada horizontal de la ilustración vista desde el frente (-Z).
    # En esa vista, la derecha de la imagen corresponde a -X del modelo.
    x = -radius_at(y) * np.sin(theta)
    front = np.cos(theta) > .10
    surface = np.ones((h, w, 3), dtype=np.float32) * rgb(spec['body'])

    def paint(mask, color):
        surface[np.broadcast_to(mask, (h, w))] = rgb(color)

    if key == 'mitico':
        a = (.5 + .5*np.sin(theta*2 + y*4 + .65*np.sin(theta*3-y*2))) ** 2
        b = (.5 + .5*np.cos(theta*3 - y*5)) ** 4
        surface = surface*(1-.66*a[:, :, None]) + rgb('#EF54D9')*.66*a[:, :, None]
        surface = surface*(1-.62*b[:, :, None]) + rgb('#43CAFF')*.62*b[:, :, None]
        wisps=np.zeros((h,w),dtype=np.float32)
        for frequency,weight in ((9,.075),(17,.045),(31,.025),(53,.012)):
            wisps += weight*np.sin(theta*frequency+y*frequency*.31+np.sin(y*7))*np.cos(theta*(frequency-2)-y*frequency*.57)
        surface=np.clip(surface+wisps[:,:,None]*np.array([1.0,.72,1.15]),0,1)
        rng = np.random.default_rng(20261021)
        uu, vv = np.meshgrid(np.arange(w), np.arange(h))
        for _ in range(250):
            sx, sy = int(rng.integers(2, w-2)), int(rng.integers(2, h-2))
            r = int(rng.integers(1, 3))
            paint((uu-sx)**2 + (vv-sy)**2 < r*r, '#F7FBFF')
        for cx, cy, r in [(-.27, .64, .085), (.29, -.35, .080), (.20, .93, .055)]:
            paint(poly_mask(x, y, star(cx, cy, r, 4)) & front, '#FFE974')
    if key == 'raro':
        mint = front & (x < .13) & (y > -.57)
        paint(mint, '#30DFAD')
        for t in (-.18, .27, .72, 1.17):
            paint(mint & (np.abs(y-1.3*x-t) < .068), '#F7FBFF')
        paint((y > -.81) & (y < -.68), '#078C79')
    elif key == 'comun':
        paint((y > -.78) & (y < -.69), '#39C7FA')
        paint((y > -.91) & (y < -.85), '#FFD43B')
        for cx, cy, r in [(-.18, .67, .12), (-.30, .45, .062)]:
            paint(poly_mask(x, y, star(cx, cy, r)) & front, '#FFD43B')
        moon = (x*x + (y+.43)**2 < .132**2) & (((x-.063)**2 + (y+.375)**2) > .124**2)
        paint(moon & front, '#FFD43B')
    elif key == 'epico':
        paint((y > -.88) & (y < -.72), '#FFE34D')
        bolt = [(-.05,.33), (.08,.13), (.025,.14), (.10,-.16), (-.09,.055), (-.035,.045)]
        for side in (-1, 1):
            points = [(side*(.36+px), .31+py) for px, py in bolt]
            paint(poly_mask(x, y, points) & front, '#FFE34D')
    elif key == 'legendario':
        paint((y > -.86) & (y < -.79), '#FFE58A')
        feather = [(.245,.47), (.29,.34), (.40,.41), (.36,.24), (.47,.27),
                   (.40,.08), (.47,.09), (.34,-.10), (.23,-.15), (.29,.03), (.24,.21)]
        for side in (-1, 1):
            paint(poly_mask(x, y, [(side*px, py) for px, py in feather]) & front, '#FF7A24')
    elif key == 'mitico':
        paint((y > -.88) & (y < -.75), '#B889FF')

    # Nariz del mismo Body, dibujada en el atlas en lugar de objeto suelto.
    paint(y >= .79, spec['nose'])
    seam = np.abs(y - .79) < .008
    surface[np.broadcast_to(seam, (h, w))] *= .74
    for seam_u in (.25, .75):
        mask = np.broadcast_to(np.abs(u-seam_u) < .0014, (h,w))
        surface[mask] *= .83
    if key in ('comun', 'raro'):
        for cx, cy in [(-.36,.36), (.36,.36), (-.31,-.43), (.31,-.43)]:
            paint(((x-cx)**2+(y-cy)**2 < .018**2) & front, '#B7C5D7')
    pixels[y0:y1, x0:x1, :3] = np.clip(surface, 0, 1)

    # Aletas: mapa proyectado, dibujo pintado; bordes y plumas no consumen triángulos.
    x0, y0, x1, y1 = FIN_RECT
    xx, yy = np.meshgrid(np.linspace(.40,1.18,x1-x0), np.linspace(-1.32,-.12,y1-y0))
    tile = np.ones((y1-y0,x1-x0,3), dtype=np.float32)*rgb(spec['fin'])
    contour = WING if key == 'legendario' else (FAST_FIN if key == 'raro' else NORMAL_FIN)
    distance = np.full(xx.shape, 100.0)
    for i, (ax, ay) in enumerate(contour):
        bx, by = contour[i-1]
        t = np.clip(((xx-ax)*(bx-ax)+(yy-ay)*(by-ay))/((bx-ax)**2+(by-ay)**2+1e-9),0,1)
        distance = np.minimum(distance, np.sqrt((xx-ax-t*(bx-ax))**2+(yy-ay-t*(by-ay))**2))
    tile[distance < .028] = rgb(spec['edge'])
    if key in ('comun','epico','mitico'):
        color = '#FFD43B' if key == 'comun' else ('#833CE5' if key == 'epico' else '#EF54D9')
        tile[poly_mask(xx,yy,star(.76,-.88,.105))] = rgb(color)
    if key == 'legendario':
        for level in (-.50,-.76,-.99):
            stripe = np.abs(yy-(level+.34*(xx-.63))) < .018
            tile[stripe & (xx > .55)] = rgb('#FFE58A')
    pixels[y0:y1,x0:x1,:3] = tile

    # Ventana azul, con reflejos pintados para conservar lectura fuera de Blender.
    x0,y0,x1,y1 = GLASS_RECT
    gx, gy = np.meshgrid(np.linspace(-1,1,x1-x0),np.linspace(-1,1,y1-y0))
    edge = np.clip(np.sqrt(gx*gx+gy*gy),0,1)
    glass = rgb('#075AF5')[None,None,:]*(1-.32*edge[:,:,None])
    glass = np.broadcast_to(glass,(y1-y0,x1-x0,3)).copy()
    for cx,cy,rx,ry,color in [(-.40,.48,.19,.11,'#B8F7FF'),(-.59,-.42,.14,.08,'#69E9FF'),(.49,.55,.10,.19,'#F7FBFF')]:
        glass[((gx-cx)/rx)**2+((gy-cy)/ry)**2 < 1] = rgb(color)
    pixels[y0:y1,x0:x1,:3] = glass
    for i,name in enumerate(SWATCHES):
        x0,y0=800+(i%2)*104,536+(i//2)*58
        pixels[y0:y0+48,x0:x0+88,:3]=rgb(colors[name])
    image=bpy.data.images.new('rocket_'+key+'_atlas',width=1024,height=1024,alpha=True)
    image.colorspace_settings.name='sRGB'
    image.pixels.foreach_set(pixels.ravel())
    image.filepath_raw=str(OUT/f'rocket_{key}_atlas.png')
    image.file_format='PNG'
    image.save()
    return image


def material(name,image,roughness=.27,metallic=.06,emission=0):
    mat=bpy.data.materials.new(name)
    mat.use_nodes=True
    bsdf=mat.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Roughness'].default_value=roughness
    bsdf.inputs['Metallic'].default_value=metallic
    bsdf.inputs['Coat Weight'].default_value=.32
    tex=mat.node_tree.nodes.new('ShaderNodeTexImage')
    tex.image=image
    tex.interpolation='Linear'
    mat.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
    if emission:
        mat.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Emission Color'])
        bsdf.inputs['Emission Strength'].default_value=emission
    return mat


def rect_uv(rect,u,v):
    a,b,c,d=rect
    return ((a+(c-a)*u)/1024,(b+(d-b)*v)/1024)


def swatch_uv(color,count):
    i=SWATCHES.index(color)
    a,b=800+(i%2)*104,536+(i//2)*58
    return [((a+44+18*math.cos(k*2*math.pi/count))/1024,
             (b+24+12*math.sin(k*2*math.pi/count))/1024) for k in range(count)]


def make_mesh(name,vertices,faces,mat,uvs=None,color='fin',pivot=(0,0,0),bevel=0):
    p=Vector(pivot)
    mesh=bpy.data.meshes.new(name+'Mesh')
    mesh.from_pydata([tuple(C@(Vector(v)-p)) for v in vertices],[],faces)
    mesh.update()
    mesh.validate(verbose=False)
    obj=bpy.data.objects.new(name,mesh)
    bpy.context.collection.objects.link(obj)
    obj.location=C@p
    mesh.materials.append(mat)
    uv_layer=mesh.uv_layers.new(name='AtlasUV')
    for n,poly in enumerate(mesh.polygons):
        coords=uvs[n] if uvs is not None else swatch_uv(color,len(poly.loop_indices))
        for li,uv in zip(poly.loop_indices,coords): uv_layer.data[li].uv=uv
        poly.use_smooth=True
    bm=bmesh.new();bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
    bm.to_mesh(mesh);bm.free()
    if bevel:
        bpy.context.view_layer.objects.active=obj
        obj.select_set(True)
        mod=obj.modifiers.new('RoundedToyEdges','BEVEL')
        mod.width=bevel;mod.segments=2
        bpy.ops.object.modifier_apply(modifier=mod.name)
        normal=obj.modifiers.new('WeightedPlasticNormals','WEIGHTED_NORMAL')
        normal.keep_sharp=True;normal.weight=35
        bpy.ops.object.modifier_apply(modifier=normal.name)
        obj.select_set(False)
    return obj


def lathe(name,profile,segments,mat,body=False,offset=(0,0,0),colors=None):
    vertices=[];rings=[]
    for y,r in profile:
        ids=[]
        for j in range(1 if r==0 else segments):
            theta=(j/segments-.5)*2*math.pi
            ids.append(len(vertices))
            vertices.append((offset[0]+r*math.sin(theta),y,offset[2]-r*math.cos(theta)))
        rings.append(ids)
    faces=[];uvs=[]
    for k in range(len(rings)-1):
        a,b=rings[k:k+2]
        for j in range(segments):
            if len(b)==1: face=[a[j],a[(j+1)%segments],b[0]]
            elif len(a)==1: face=[a[0],b[(j+1)%segments],b[j]]
            else: face=[a[j],a[(j+1)%segments],b[(j+1)%segments],b[j]]
            faces.append(face)
            if body:
                v0=(profile[k][0]+1.12)/2.52;v1=(profile[k+1][0]+1.12)/2.52
                coords=[(j/segments,v0),((j+1)/segments,v0),((j+1)/segments,v1),(j/segments,v1)]
                if len(b)==1: coords=[coords[0],coords[1],((j+.5)/segments,v1)]
                uvs.append([rect_uv(BODY_RECT,u,v) for u,v in coords])
            else:
                color=colors[k] if colors else 'silver'
                uvs.append(swatch_uv(color,len(face)))
    closed_profile=not body and abs(profile[0][0]-profile[-1][0])<1e-8
    if closed_profile:
        for j in range(segments):
            faces.append([rings[-1][j],rings[-1][(j+1)%segments],rings[0][(j+1)%segments],rings[0][j]])
            uvs.append(swatch_uv('dark',4))
    else:
        for ids in (rings[0],rings[-1]):
            if len(ids)>1:
                faces.append(list(reversed(ids)))
                uvs.append(swatch_uv('dark' if not body else 'white',len(ids)))
    return make_mesh(name,vertices,faces,mat,uvs)


def torus(name,center,major,minor,mat,axis='z',n=32,m=6,color='silver',ring=False):
    vertices=[];faces=[];uvs=[]
    for i in range(n):
        t=i/n*2*math.pi
        for j in range(m):
            p=j/m*2*math.pi;r=major+minor*math.cos(p)
            if axis=='z': v=Vector((r*math.cos(t),r*math.sin(t),minor*math.sin(p)))
            else: v=Vector((r*math.cos(t),minor*math.sin(p),r*math.sin(t)))
            if ring: v=Matrix.Rotation(math.radians(15),3,'Z')@v
            vertices.append(tuple(v+Vector(center)))
    for i in range(n):
        for j in range(m):
            faces.append([i*m+j,((i+1)%n)*m+j,((i+1)%n)*m+(j+1)%m,i*m+(j+1)%m])
            col=('cyan' if j in (0,1,7) else ('bright' if j in (2,6) else 'pink')) if ring else color
            uvs.append(swatch_uv(col,4))
    return make_mesh(name,vertices,faces,mat,uvs)


def ellipsoid(name,center,radii,mat,segments=24,rings=10,color='blue',window=False):
    vertices=[tuple(Vector(center)+Vector((0,0,-radii[2])))];faces=[];uvs=[]
    for k in range(1,rings):
        a=-math.pi/2+k/rings*math.pi
        for j in range(segments):
            t=j/segments*math.tau
            vertices.append((center[0]+radii[0]*math.cos(a)*math.cos(t),
                             center[1]+radii[1]*math.cos(a)*math.sin(t),
                             center[2]+radii[2]*math.sin(a)))
    vertices.append(tuple(Vector(center)+Vector((0,0,radii[2]))))
    for j in range(segments): faces.append([0,1+(j+1)%segments,1+j])
    for k in range(rings-2):
        for j in range(segments):
            a=1+k*segments+j;b=1+k*segments+(j+1)%segments
            faces.append([a,b,b+segments,a+segments])
    last=len(vertices)-1
    for j in range(segments): faces.append([last,last-1-j,last-1-(j+1)%segments])
    for face in faces:
        if window:
            uvs.append([rect_uv(GLASS_RECT,.5-(vertices[i][0]-center[0])/(radii[0]*2),
                                 .5+(vertices[i][1]-center[1])/(radii[1]*2)) for i in face])
        else: uvs.append(swatch_uv(color,len(face)))
    return make_mesh(name,vertices,faces,mat,uvs)


def fin(name,contour,mat,side=1,front=False,pivot=(0,0,0)):
    vertices=[];depth=.075
    for z in (-depth,depth):
        for x,y in contour:
            vertices.append((z if front else side*x,y,side*x*.77 if front else z))
    n=len(contour)
    faces=[list(range(n-1,-1,-1)),list(range(n,n*2))]
    faces += [[i,(i+1)%n,(i+1)%n+n,i+n] for i in range(n)]
    uvs=[]
    for index,face in enumerate(faces):
        if index==0 and not front:
            coords=[rect_uv(FIN_RECT,(contour[i%n][0]-.40)/.78,(contour[i%n][1]+1.32)/1.20) for i in face]
        else: coords=swatch_uv('fin',len(face))
        uvs.append(coords)
    return make_mesh(name,vertices,faces,mat,uvs,pivot=pivot,bevel=.022)


def join_parts(name,objects):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects: obj.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    if len(objects)>1: bpy.ops.object.join()
    obj=objects[0];obj.name=name
    bpy.context.scene.cursor.location=(0,0,0)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    obj.select_set(False)
    return obj


def stats(objects):
    coords=[obj.matrix_world@v.co for obj in objects for v in obj.data.vertices]
    logical=[CI@p for p in coords]
    low=Vector(tuple(min(p[i] for p in logical) for i in range(3)))
    high=Vector(tuple(max(p[i] for p in logical) for i in range(3)))
    triangles=0
    for obj in objects:
        obj.data.calc_loop_triangles();triangles+=len(obj.data.loop_triangles)
    return {'triangles':triangles,'bounds_min_m':[round(v,6) for v in low],
            'bounds_max_m':[round(v,6) for v in high],
            'size_m':[round(v,6) for v in high-low],
            'bounds_center_m':[round(v,6) for v in (low+high)*.5]}


def build(key):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene=bpy.context.scene
    scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
    image=make_atlas(key)
    plastic=material('AtlasPlastic',image)
    metal=material('AtlasSilver',image,.23,.65)
    glass=material('AtlasBlueGlass',image,.13,.14)
    light=material('AtlasRingGlow',image,.25,.1,.35)
    body_parts=[lathe('Capsule',PROFILE,32,plastic,body=True)]
    # Bezel grueso, unido al Body: no flota delante del casco curvo.
    n=32;verts=[]
    for r,z in [(.34,-.47),(.34,-.59),(.274,-.615),(.274,-.47)]:
        for j in range(n):
            t=j/n*math.tau;verts.append((r*math.cos(t),.20+r*math.sin(t),z))
    faces=[]
    for k in range(4):
        for j in range(n): faces.append([k*n+j,k*n+(j+1)%n,((k+1)%4)*n+(j+1)%n,((k+1)%4)*n+j])
    body_parts.append(make_mesh('BezelMount',verts,faces,metal,color='silver'))
    body_parts.append(torus('SilverRim',(0,.20,-.603),.305,.025,metal))
    for j in range(8):
        t=j/8*math.tau
        body_parts.append(ellipsoid('Rivet',(.307*math.cos(t),.20+.307*math.sin(t),-.626),
                                     (.017,.017,.008),metal,8,4,'silver'))
    body=join_parts('Body',body_parts)
    window=ellipsoid('Window',(0,.20,-.617),(.275,.275,.080),glass,24,10,window=True)
    contour=FAST_FIN if key=='raro' else NORMAL_FIN
    fin_parts=[fin('FrontFin',NORMAL_FIN,plastic,-1,True),fin('RearFin',NORMAL_FIN,plastic,1,True)]
    wings=[]
    if key=='legendario':
        wings=[fin('WingLeft',WING,plastic,-1,pivot=(-.46,-.54,0)),
               fin('WingRight',WING,plastic,1,pivot=(.46,-.54,0))]
    else:
        fin_parts += [fin('LeftFin',contour,plastic,-1),fin('RightFin',contour,plastic,1)]
    fins=join_parts('Fins',fin_parts)
    nozzle_parts=[];nozzle_positions=[]
    centers=[-.205,.205] if key=='epico' else [0]
    for x in centers:
        scale=.64 if key=='epico' else 1
        profile=[(-1.075,.24*scale),(-1.12,.29*scale),(-1.19,.30*scale),
                 (-1.225,.265*scale),(-1.25,.31*scale),(-1.31,.31*scale),
                 (-1.36,.29*scale),(-1.40,.27*scale),(-1.40,.18*scale),
                 (-1.26,.16*scale),(-1.075,.16*scale)]
        nozzle_parts.append(lathe('Engine',profile,20,metal,offset=(x,0,0),
                                  colors=['silver','silver','dark','silver','silver','dark','silver','dark','dark','dark']))
        nozzle_positions.append([x,-1.40,0])
    nozzle=join_parts('Nozzle',nozzle_parts)
    pieces=[body,fins,window,nozzle]+wings
    if key=='mitico':
        ring=torus('Ring',(0,-.54,0),1.095,.035,light,'y',64,8,ring=True)
        pieces.append(ring)
    root=bpy.data.objects.new('Rocket_'+key.capitalize(),None)
    bpy.context.collection.objects.link(root)
    root.empty_display_type='PLAIN_AXES';root.empty_display_size=.2
    root['design_units']='meters';root['design_up']='+Y';root['design_front']='-Z'
    for obj in pieces:
        obj.parent=root
        obj['role']=obj.name
        obj['pivot_m']=list(CI@obj.location)
        bpy.context.view_layer.objects.active=obj
        mod=obj.modifiers.new('ExportTriangles','TRIANGULATE')
        mod.keep_custom_normals=True
        bpy.ops.object.modifier_apply(modifier=mod.name)
        # El bisel puede producir triángulos diminutos junto a esquinas casi colineales.
        # Limpiarlos antes de exportar evita su colapso al convertir a float32 en FBX.
        bm=bmesh.new();bm.from_mesh(obj.data)
        bmesh.ops.dissolve_degenerate(bm,dist=1e-6,edges=list(bm.edges))
        bmesh.ops.triangulate(bm,faces=list(bm.faces))
        tiny=[f for f in bm.faces if f.calc_area()<1e-10]
        if tiny: bmesh.ops.delete(bm,geom=tiny,context='FACES_ONLY')
        wire=[e for e in bm.edges if not e.link_faces]
        if wire: bmesh.ops.delete(bm,geom=wire,context='EDGES')
        loose=[v for v in bm.verts if not v.link_edges]
        if loose: bmesh.ops.delete(bm,geom=loose,context='VERTS')
        bm.to_mesh(obj.data);bm.free();obj.data.update()
    bpy.context.view_layer.update()
    info=stats(pieces)
    assert info['triangles']<6000,(key,info)
    assert abs(info['size_m'][1]-2.8)<.0001,(key,info)
    assert max(abs(v) for v in info['bounds_center_m'])<.002,(key,info)
    bpy.ops.object.select_all(action='DESELECT')
    root.select_set(True)
    for obj in pieces: obj.select_set(True)
    bpy.context.view_layer.objects.active=root
    bpy.ops.export_scene.fbx(filepath=str(OUT/f'rocket_{key}.fbx'),use_selection=True,
        object_types={'MESH','EMPTY'},global_scale=1,apply_unit_scale=True,
        apply_scale_options='FBX_SCALE_UNITS',axis_forward='-Z',axis_up='Y',
        use_space_transform=True,bake_space_transform=False,mesh_smooth_type='FACE',
        use_mesh_modifiers=True,use_custom_props=True,add_leaf_bones=False,bake_anim=False,
        path_mode='RELATIVE',embed_textures=False)
    # Archivo nativo solo con geometría y materiales; sin cámaras, luces ni animaciones.
    for area in bpy.context.screen.areas if bpy.context.screen else []:
        if area.type=='VIEW_3D': area.spaces.active.shading.type='MATERIAL'
    image.pack()
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/f'rocket_{key}.blend'),check_existing=False)
    info.update(nozzles_m=nozzle_positions,window_center_m=[0,.20,-.617],
                window_front_m=[0,.20,-.697],pilot_clearance_center_m=[0,.20,-.87],
                fire_direction=[0,-1,0],source_pieces=[o.name for o in pieces])
    return info


def aim(obj,target):
    obj.rotation_euler=(Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()


def render_imported(key):
    scene=bpy.context.scene
    scene.render.engine='CYCLES'
    scene.cycles.device='CPU';scene.cycles.samples=96
    # Funciona también en builds de Blender sin OpenImageDenoise.
    scene.cycles.use_denoising=False
    scene.render.resolution_x=1024;scene.render.resolution_y=1024
    scene.render.resolution_percentage=100
    scene.render.film_transparent=True
    scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
    scene.view_settings.view_transform='Standard'
    scene.view_settings.look='None'
    world=bpy.data.worlds.new('NeutralStudio')
    world.use_nodes=True
    world.node_tree.nodes['Background'].inputs[0].default_value=(.78,.83,.94,1)
    world.node_tree.nodes['Background'].inputs[1].default_value=.45
    scene.world=world
    for name,location,power,size in [('Key',(-3,4,5),430,4),('Fill',(4,3,2),230,3),('Rim',(-1,-4,3),460,3)]:
        data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size
        obj=bpy.data.objects.new(name,data);scene.collection.objects.link(obj);obj.location=location;aim(obj,(0,0,0))
    data=bpy.data.cameras.new('AssetCamera');data.type='ORTHO';data.ortho_scale=3.65
    camera=bpy.data.objects.new('AssetCamera',data);scene.collection.objects.link(camera)
    camera.location=(5.5,8,3.0);aim(camera,(0,0,0));scene.camera=camera
    scene.render.filepath=str(OUT/f'preview_{key}.png')
    bpy.ops.render.render(write_still=True)


def verify(key,source_info=None):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
    path=OUT/f'rocket_{key}.fbx'
    assert path.is_file() and path.stat().st_size>10000,path
    from io_scene_fbx import parse_fbx
    fbx_tree,fbx_version=parse_fbx.parse(str(path))
    global_settings=next(e for e in fbx_tree.elems if e.id==b'GlobalSettings')
    properties=next(e for e in global_settings.elems if e.id==b'Properties70')
    axes={e.props[0].decode():e.props[-1] for e in properties.elems if e.id==b'P'}
    assert axes['UpAxis']==1 and axes['UpAxisSign']==1,axes
    assert abs(axes['UnitScaleFactor']-100)<1e-6,axes
    bpy.ops.import_scene.fbx(filepath=str(path),use_anim=False,use_image_search=True)
    bpy.context.view_layer.update()
    meshes=[obj for obj in scene.objects if obj.type=='MESH']
    roots=[obj for obj in scene.objects if obj.type=='EMPTY' and obj.parent is None]
    assert len(roots)==1,(key,[o.name for o in roots])
    root=roots[0]
    assert root.location.length<1e-5 and max(abs(v-1) for v in root.scale)<1e-5
    names={o.name for o in meshes}
    required={'Body','Fins','Window','Nozzle'}
    if key=='legendario': required|={'WingLeft','WingRight'}
    if key=='mitico': required|={'Ring'}
    assert names==required,(key,names,required)
    assert not bpy.data.actions, 'No debe haber animaciones horneadas'
    assert not bpy.data.texts, 'No debe haber scripts dentro del modelo'
    for obj in meshes:
        assert obj.parent==root,(key,obj.name,'parent')
        assert obj.data.uv_layers.active is not None,(key,obj.name,'UV')
        uv=[tuple(loop.uv) for loop in obj.data.uv_layers.active.data]
        assert uv and all(math.isfinite(v) and -.001<=v<=1.001 for pair in uv for v in pair),(key,obj.name,'UV bounds')
        assert obj.scale.to_tuple()==(1.,1.,1.),(key,obj.name,'scale')
        bm=bmesh.new();bm.from_mesh(obj.data)
        assert all(f.calc_area()>1e-12 for f in bm.faces),(key,obj.name,'degenerate face')
        bm.free()
    info=stats(meshes)
    info['fbx_version']=fbx_version
    info['fbx_axes_units']={k:axes[k] for k in ('UpAxis','UpAxisSign','FrontAxis','FrontAxisSign','UnitScaleFactor')}
    assert info['triangles']<6000,(key,info)
    assert abs(info['size_m'][1]-2.8)<.0002,(key,info)
    assert max(abs(v) for v in info['bounds_center_m'])<.002,(key,info)
    if source_info:
        assert info['triangles']==source_info['triangles'],(key,'triangle round-trip')
        assert max(abs(a-b) for a,b in zip(info['size_m'],source_info['size_m']))<.0001
    # Medir cada componente conectado de Nozzle en el FBX reabierto, no solo el ancho total.
    nozzle=bpy.data.objects['Nozzle']
    adjacency=[set() for _ in nozzle.data.vertices]
    for e in nozzle.data.edges:
        a,b=e.vertices;adjacency[a].add(b);adjacency[b].add(a)
    remaining=set(range(len(adjacency)));emitters=[]
    while remaining:
        start=remaining.pop();stack=[start];component=[start]
        while stack:
            for other in adjacency[stack.pop()]:
                if other in remaining:
                    remaining.remove(other);stack.append(other);component.append(other)
        points=[CI@(nozzle.matrix_world@nozzle.data.vertices[i].co) for i in component]
        low=[min(p[i] for p in points) for i in range(3)]
        high=[max(p[i] for p in points) for i in range(3)]
        emitters.append([round((low[0]+high[0])/2,6),round(low[1],6),round((low[2]+high[2])/2,6)])
    emitters.sort()
    expected=[[-.205,-1.4,0],[.205,-1.4,0]] if key=='epico' else [[0,-1.4,0]]
    assert len(emitters)==len(expected),(key,emitters)
    assert all((Vector(a)-Vector(b)).length<.0001 for a,b in zip(emitters,expected)),(key,emitters)
    info['nozzles_m']=emitters
    info['nozzle_components_verified']=len(emitters)
    info['fire_direction']=[0,-1,0]
    window_points=[CI@(bpy.data.objects['Window'].matrix_world@v.co) for v in bpy.data.objects['Window'].data.vertices]
    center=[(min(p[i] for p in window_points)+max(p[i] for p in window_points))/2 for i in range(3)]
    info['window_center_m']=[round(v,6) for v in center]
    info['window_front_m']=[round(center[0],6),round(center[1],6),round(min(p.z for p in window_points),6)]
    info['pilot_clearance_center_m']=[0,.20,-.87]
    assert abs(center[1]-.20)<1e-4 and center[2]<-.60,(key,center)
    if key=='legendario':
        for name,expected in [('WingLeft',(-.46,-.54,0)),('WingRight',(.46,-.54,0))]:
            pivot=CI@bpy.data.objects[name].matrix_world.translation
            assert (pivot-Vector(expected)).length<.0001,(name,pivot)
    if key=='mitico':
        ring=bpy.data.objects['Ring'];window=bpy.data.objects['Window']
        assert ring.matrix_world.translation.length<.0001
        body=bpy.data.objects['Body']
        bvh=BVHTree.FromObject(body,bpy.context.evaluated_depsgraph_get())
        distances=[bvh.find_nearest(v.co)[3] for v in ring.data.vertices]
        info['ring_body_min_clearance_m']=round(min(distances),6)
        ry=[(CI@(ring.matrix_world@v.co)).y for v in ring.data.vertices]
        wy=[(CI@(window.matrix_world@v.co)).y for v in window.data.vertices]
        info['ring_window_vertical_clearance_m']=round(min(wy)-max(ry),6)
        assert info['ring_body_min_clearance_m']>.15,info
        assert info['ring_window_vertical_clearance_m']>.02,info
    atlas=OUT/f'rocket_{key}_atlas.png'
    image=bpy.data.images.load(str(atlas),check_existing=True)
    assert tuple(image.size)==(1024,1024),atlas
    for mat in bpy.data.materials:
        if mat.use_nodes:
            for node in mat.node_tree.nodes:
                if node.type=='TEX_IMAGE':
                    assert node.image and tuple(node.image.size)==(1024,1024),(key,mat.name,'texture')
    info['pieces']=[{'name':o.name,'triangles':len(o.data.loop_triangles),
                    'pivot_m':[round(v,6) for v in CI@o.matrix_world.translation]} for o in sorted(meshes,key=lambda o:o.name)]
    info['fbx_reimport_verified']=True
    info['texture_size']=[1024,1024]
    info['fbx_sha256']=hashlib.sha256(path.read_bytes()).hexdigest()
    info['atlas_sha256']=hashlib.sha256(atlas.read_bytes()).hexdigest()
    print('VERIFIED',key,json.dumps(info,ensure_ascii=False),flush=True)
    if not ARGS.skip_render: render_imported(key)
    return info


def main():
    report={'tool':'Blender '+bpy.app.version_string,'prompt':14,'units':'meters',
            'fbx_up':'+Y','fbx_front':'-Z','render_source':'FBX reimportado',
            'roblox_studio_import_tested':False,'rockets':{}}
    for key in SPECS:
        if ARGS.only and key!=ARGS.only: continue
        source_info=None if ARGS.verify_only else build(key)
        report['rockets'][key]=verify(key,source_info)
        (OUT/f'verification_{key}.json').write_text(json.dumps(report['rockets'][key],ensure_ascii=False,indent=2)+'\n')
    (OUT/'VALIDACION.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print('OK: '+', '.join(report['rockets']),flush=True)


if __name__=='__main__': main()

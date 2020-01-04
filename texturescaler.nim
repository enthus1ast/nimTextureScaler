import imageman
import cligen
# import glob
import glm/vec
import parsecfg
import os, strutils, tables
# for outSize in outSizes:
# import glob

var config = loadConfig(getAppDir() / "texturescaler.ini")
# var outFormat = "${filename}__${x}_${y}.${ext}"
var outFormat = config.getSectionValue("default", "outFormat")

iterator outSizes(): Vec2[int] =
  for outSize in config["outSizes"].keys:
    let parts = outSize.strip().split(" ")
    yield vec2(parts[0].parseInt, parts[1].parseInt)

proc genOutFileName(imagePath: string, outSize: Vec2[int], outExt: string): string =
  let (dir, filename, ext) = splitFile(imagePath)
  return outFormat % [
    "filename", dir / filename, 
    "x", $outSize.x, 
    "y", $outSize.y, 
    "ext", "." & outExt
    ]


proc scale(img: Image[ColorRGBU], imagePath: string, outSize: Vec2[int], force: bool, outExt: string): tuple[outPath: string, img: Image[ColorRGBU]] =
  let outPath = genOutFileName(imagePath, outSize, outExt)
  if not force:
    if existsFile(outPath): return
  var outp=""
  outp &= ($img.width & "x" & $img.height).align(10)
  outp &= " -> "
  outp &= ($outSize.x & "x" & $outSize.y).align(10)
  outp &= " " & outPath
  echo outp
  # case config.getSectionValue("default", "algo")
  # let img2 = img.resizedBicubic(outSize.x, outSize.y)
  # let img2 = img.resizedTrilinear(outSize.x, outSize.y)
  let img2 = img.resizedNN(outSize.x, outSize.y)
  return (outPath, img2)

iterator walk(pathToWalk: string, recursive: bool): string =
  var filter: set[PathComponent]
  if recursive: 
    filter.incl pcDir
  for path in walkDirRec(pathToWalk, followFilter = filter):
    yield path

proc main(dir: string, recursive = false, force = false, inExt = "png", outExt = "png") =
  discard
  echo dir
  echo recursive
  echo force
  for path in walk(dir, recursive):
    ## cannot use glob glob is buggy with newest nim atm
    if not path.toLower.endswith(inExt.toLower): continue
    if path.contains(config.getSectionValue("default", "skipFiles")): continue
    let img = loadImage[ColorRGBU](path)
    echo "[+] ", path
    for outSize in outSizes():
      let (outPath, img2) = img.scale(path, outSize, force, outExt)
      case outExt
      of "png":
        img2.savePNG(outPath)
      of "jpg", "jpeg":
        img2.saveJPG(outPath) 


when isMainModule:
  dispatch main
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

proc genInfo(outPath: string, orgSize, outSize: Vec2[int]): string =
  result=""
  result &= ($orgSize.x & "x" & $orgSize.y).align(10)
  result &= " -> "
  result &= ($outSize.x & "x" & $outSize.y).align(10)
  result &= " " & outPath

proc scale(img: Image[ColorRGBU], outSize: Vec2[int]): Image[ColorRGBU] =
  # case config.getSectionValue("default", "algo")
  # let img2 = img.resizedBicubic(outSize.x, outSize.y)
  # let img2 = img.resizedTrilinear(outSize.x, outSize.y)
  return img.resizedNN(outSize.x, outSize.y)
  

iterator walk(pathToWalk: string, recursive: bool): string =
  var filter: set[PathComponent]
  if recursive: 
    filter.incl pcDir
  for path in walkDirRec(pathToWalk, followFilter = filter):
    yield path

proc getOrgSize(img: Image[ColorRGBU]): Vec2[int] =
  return vec2[int](img.width, img.height)

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
    let orgSize = img.getOrgSize
    echo "[+] ", path

    for outSize in outSizes():
      # let (outPath, img2) = img.scale(path, outSize, force, outExt)
      let outPath = genOutFileName(path, outSize, outExt)

      if not force:
        if existsFile(outPath): continue

      # echo outPath 
      echo genInfo(outPath, orgSize, outSize)
      let img2 = img.scale(outSize)
      case outExt
      of "png":
        img2.savePNG(outPath)
      of "jpg", "jpeg":
        img2.saveJPG(outPath) 


when isMainModule:
  dispatch main
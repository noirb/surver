import asynchttpserver, asyncdispatch, system, json, strutils, os
import gcap

var basePage: string
var s: string
var dataFile = "participant_data.json"
var port: int = 8080

var cmd = newCmdLine("Survey Surver", "0.0.2")
cmd.add(newValueArg[string]("c", "cfg", "surver config file", true, s))
cmd.add(newValueArg[string]("d", "data", "data file to store results in (will be appended to if it exists, created if it doesn't -- defaults to '" & dataFile & "')", false, dataFile))
cmd.add(newValueArg[int]("p", "port", "port to surve on (" & $port & " by default)", false, port))
cmd.parse()

basePage = "index.html"

echo("Loading survey data from: " & s)
var surveys = parseJson(readFile(s))
var participant_data: JsonNode
var server = newAsyncHttpServer()

proc loadData(filename: string): JsonNode = 
  try:
    return parseJson(readFile(filename))
  except JsonParsingError:
    echo("ERROR: JsonParsingError in file '" & filename & "'")
    raise
  except IOError:
    return %*[]
  except:
    echo("ERROR: Unknown exception raised when trying to load file: '" & filename & "'")
    raise

proc doCmd(cmd: string, data: string): string =
  echo(cmd)
  case cmd:
    of "new_user":
      var group = "A"
      if participant_data.len > 0 and participant_data[participant_data.len-1]["group"].getStr() == "A":
        group = "B"

      var id = participant_data.len + 1
      participant_data.add(%*{"id": id, "group": group})
      echo("\t" & $id & " : Group " & group);
      return $(%* {"id": id, "group": group, "status": "success"})
    of "get_survey":
      var jdata = parseJson(data)
      echo("\t" & jdata["survey"].getStr())
      for s in surveys["surveys"]:
        if s["name"].getStr() == jdata["survey"].getStr():
          var res = %*{"status":"success"}
          res.add("survey", parseJson(readFile(s["location"].getStr())))
          return $res
      echo("\t...not found")
      return $(%* {"status": "Failed: Unknown survey"})
    of "list_surveys":
      var res = %*{"status":"success"}
      var s = newSeq[string]()
      for survey in surveys["surveys"]:
        s.add(survey["name"].getStr())
      res.add("surveys", %s)
      return $res
    of "submit_result":
      # find matching id entry
      var participant: ptr JsonNode = nil
      var jdata = parseJson(data)
      echo("\tParsed json")
      echo("\tSearching for id " & $jdata["id"] & "...")
      for p in participant_data.mitems:
        if p["id"].getInt() == jdata["id"].getInt():
            echo("\t\tFound participant : " & $jdata["id"])
            participant = addr p
            break

      if participant == nil:
        return $(%* {"status": "Failed: Unknown participant"})
      for k,v in jdata:
        participant[].add(k, v)

      echo ("\tWriting data to output file")
      writeFile(dataFile, participant_data.pretty)
      return $(%* {"satus": "success"})

  return $(%* {"status": "Failed: Unknown command"})

proc contentType(filename: string): string =
    var ext = splitFile(filename).ext
    case(ext):
        of ".css":
            return "text/css"
        of ".xml":
            return "text/xml"
        of ".js":
            return "text/javascript"
        of ".png":
            return "image/png"
        of ".html":
            return "text/html"
        of ".htm":
            return "text/html"
        of ".txt":
            return "text/plain"
    return ""

proc cb(req: Request) {.async, gcsafe.} =
#  echo(req)
  if req.url.path.contains('$'):
    await req.respond(Http200, doCmd(req.url.path[req.url.path.find('$')+1 .. ^1], req.body))
  elif req.url.path.len > 1:
    var targetFile = "." & req.url.path # haha security
    try:
      let resContent = readFile(targetFile)
      await req.respond(Http200, resContent, newHttpHeaders([("Content-Type",contentType(targetFile))]))
    except:
      await req.respond(Http404, "Not found, yo!")
  else:
    await req.respond(Http200, readFile(basePage))

participant_data  = loadData(dataFile)
echo($participant_data.len & " pre-existing entries found in data file")

waitFor server.serve(Port(port), cb)


import asynchttpserver, asyncdispatch, system, json, strutils
import gcap

var basePage: string
var s: string
var port: int = 8080

var cmd = newCmdLine("Survey Surver", "0.0.1")
cmd.add(newValueArg[string]("s", "survey", "survey source file", true, s))
cmd.add(newValueArg[int]("p", "port", "port to surve on", false, port))
cmd.parse()

basePage = readFile("index.html")
var surveys = parseJson(readFile(s))

var participant_data = parseJson(readFile("participant_data.json"))
echo($participant_data.len & " pre-existing entries found in data file")

var server = newAsyncHttpServer()

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
    of "submit_result":
      # find matching id entry
      var participant: ptr JsonNode = nil
      var jdata = parseJson(data)
      echo("Parsed json [" & $jdata.kind & "]: " & $jdata)
      echo("Searching for id... " & $jdata["id"])
      for p in participant_data.mitems:
        echo($p)
        if p["id"].getInt() == jdata["id"].getInt():
            echo("Found participant : " & $jdata["id"])
            participant = addr p
            break

      if participant == nil:
        return $(%* {"status": "Failed: Unknown participant"})
      for k,v in jdata:
        echo("Processing: '" & $k & "' : " & $v)
        participant[].add(k, v)

      writeFile("participant_data.json", participant_data.pretty)
      echo($participant_data)
      return $(%* {"satus": "success"})

  return $(%* {"status": "Failed: Unknown command"})

proc cb(req: Request) {.async, gcsafe.} =
#  echo(req)
  if req.url.path.contains('$'):
    await req.respond(Http200, doCmd(req.url.path[req.url.path.find('$')+1 .. ^1], req.body))
  elif req.url.path.len > 1:
    var targetFile = "." & req.url.path # haha security
    try:
      let resContent = readFile(targetFile)
      await req.respond(Http200, resContent)
    except:
      await req.respond(Http404, "Not found, yo!")
  else:
    await req.respond(Http200, basePage)

waitFor server.serve(Port(port), cb)


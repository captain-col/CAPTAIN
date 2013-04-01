#######################################################################
# This package is automatically available to python scripts in the
# CAPTAIN/scripts directory.
#
# Define a (very) simple interface to cmt.  This depends on the -xml
# interface.  This provide the functions:
#
#  captain.cmt.GetProjects(dir=".") -- Return a list of the projects
#            returned by "cmt show projects".  The actual command run
#            is "(cd <dir>; cmt show projects)"
#
#  captain.cmt.GetUses(dir=".") -- Return a list of packages returned
#            by "cmt show uses".  The actual command that is run is
#            "(cd <dir>; cmt show uses)"
#
#  captain.cmt.GetMissing(dir=".") -- Return a list of the missing
#            packages.  This is parsed from the error output of the
#            "(cd <dir>; cmt show uses)" command.
#
#  captain.cmt.GetMissingProjects(dir=".") -- Return a list of the missing
#            projects.  This is parsed from the error output of the
#            "(cd <dir>; cmt show projects)" command.
#
#  captain.cmt.GetContainer(dir=".") -- Return a Package object for
#            the package specified in the project.cmt "container"
#            directive.  The only fields that are set are the "name"
#            and "version".
# 
#  captaion.cmt.GetPackage(dir=".") -- Return a package object for the
#            current package.  This will fill "type", "name",
#            "version", "offset", and "root"
#
# This provides the classes
#
# captain.cmt.Project -- A pure data class with fields for
#    type -- String with value "project". Just says what the class is.
#          This is in both the Project and Package classes
#    name -- The name of the project.
#    version -- The version string for the project.  This is derived
#          from the subdirectory containing the project.
#    current -- True if this is the current project.
#    cmtpath -- The root of the path that would be set inside the project.
#    uses -- A list of projects used by this project.
#    clients -- A list of projects that use this project.
#    order -- ?? Defined by CMT, but I'm not sure what it is.
#
# captain.cmt.Package -- A pure data class with fields for
#     type -- String with value "package". Just says what the class is.
#           This is in both the Project and Package classes
#     name -- The name of the project.
#     version -- The version string for the project.  This is derived
#           from the subdirectory containing the project.
#     offset -- The subdirectory that contains the package.
#     root -- The package root.
#     project -- The project with this package.
#     cmtpath -- The root of the path that would be set inside the project.
#     order -- ?? Defined by CMT, but I'm not sure what it is.
#

import re
import captain.shell
import xml.parsers.expat

class Project:
    """A container for a CMT project description.  The fields are:

    type -- String with value "project". Just says what the class is.
          This is in both the Project and Package classes

    name -- The name of the project.

    version -- The version string for the project.  This is derived
          from the subdirectory containing the project.

    cmtpath -- The root of the path that would be set inside the project.

    uses -- A list of projects used by this project.

    clients -- A list of projects that use this project.

    order -- ?? Defined by CMT, but I'm not sure what it is.
    
"""
    def __init__(self):
        self.type = "project"
        self.name = None
        self.version = None
        self.current = False
        self.cmtpath = None
        self.uses = None
        self.clients = None
        self.order = None

    def __repr__(self):
        rep = "<project"
        if self.current: rep += " (current)"
        if self.name != None: rep += " n: " + str(self.name)
        else: rep += " n: None"
        if self.version != None: rep += " v: " + str(self.version)
        else: rep += " v: None"
        if self.cmtpath != None: rep += " P: " + str(self.cmtpath)
        else: rep += " P: None"
        if self.uses != None: rep += " u: " + str(self.uses)
        else: rep += " u: None"
        if self.clients != None: rep += " c: " + str(self.clients)
        else: rep += " c: None"
        if self.order != None: rep += " O: " + str(self.order)
        else: rep += " O: None"
        rep += ">"
        return rep

class Package:
    """A container for a CMT package description  The fields are:

    type -- String with value "package". Just says what the class is.
          This is in both the Project and Package classes

    name -- The name of the package.

    version -- The version string for the package.

    offset -- The subdirectory that contains the package.

    root -- The package root.

    project -- The project with this package

    cmtpath -- The root of the path that would be set inside the package.

    order -- ?? Defined by CMT, but I'm not sure what it is.

"""
    def __init__(self):
        self.type = "package"
        self.name = None
        self.offset = None
        self.root = None
        self.project = None
        self.version = None
        self.cmtpath = None
        self.clients = None
        self.order = None

    def __repr__(self):
        rep = "<package"
        rep += " n: "
        if self.offset != None: rep = rep + self.offset + "/"
        elif self.name != None: rep += self.name
        else: rep += "None"
        if self.version != None: rep += " v: " + str(self.version)
        else: rep += " v: None"
        if self.root != None: rep += " r: " + str(self.root)
        else: rep += " r: None"
        if self.project != None: rep = rep + " p: " + str(self.offset)
        if self.cmtpath != None: rep += " P: " + str(self.cmtpath)
        else: rep += " P: None"
        if self.clients != None: rep += " c: " + str(self.clients)
        if self.order != None: rep += " O: " + str(self.order)
        else: rep += " O: None"
        rep = rep + ">"
        return rep

    def SplitVersion(self):
        match=re.match(r"[^0-9]*([0-9]+)",self.version)
        if match == None: return None
        major = int(match.group(1))
        match=re.match(r"[^0-9]*[0-9]+[^0-9]+([0-9]+)",self.version)
        if match == None: return (major, 0, 0)
        minor = int(match.group(1))
        match=re.match(r"[^0-9]*[0-9]+[^0-9]+[0-9]+[^0-9]+([0-9]+)",
                       self.version)
        if match == None: return (major, minor, 0)
        patch = int(match.group(1))
        return (major, minor, patch)

# Private global variables.
_elementStack = []
_currentElement = None
_currentName = ""

def _xmlStartElement(name,attr):
    """ An internal function to handle parsing CMT XML"""
    global _elementStack
    global _currentElement
    global _currentName
    _currentName = name
    if name == "project":
        _currentElement = Project()
        if "current" in attr: _currentElement.current = True
        _elementStack.append(_currentElement)
    elif name == "package":
        _currentElement = Package()
        _elementStack.append(_currentElement)
    elif name == "projects":
        _currentElement = []
        _elementStack.append(_currentElement)
    elif name == "uses":
        _currentElement = []
        _elementStack.append(_currentElement)
    elif name == "clients":
        _currentElement = []
        _elementStack.append(_currentElement)

def _xmlEndElement(name):
    """ An internal function to handle parsing CMT XML"""
    global _elementStack
    global _currentElement
    global _currentName
    if name == "project":
        elem = _elementStack.pop()
        _currentElement = _elementStack[-1]
        _currentElement.append(elem)
    elif name == "package":
        elem = _elementStack.pop()
        _currentElement = _elementStack[-1]
        _currentElement.append(elem)
    elif name == "projects":
        _currentElement = _elementStack.pop()
    elif name == "uses":
        elem = _elementStack.pop()
        if len(_elementStack)>0:
            _currentElement = _elementStack[-1]
            _currentElement.uses = elem
        else:
            _currentElement = elem
    elif name == "clients":
        elem = _elementStack.pop()
        if len(_elementStack)>0:
            _currentElement = _elementStack[-1]
            _currentElement.clients = elem
        else:
            _currentElement = elem

def _xmlElementData(data):
    """ An internal function to handle parsing CMT XML"""
    global _currentElement
    global _currentName
    if _currentName == "name": 
        _currentElement.name = data
    if _currentName == "version": 
        _currentElement.version = data
    if _currentName == "root":
        _currentElement.root = data
    if _currentName == "cmtpath":
        _currentElement.cmtpath = data
    if _currentName == "order": 
        _currentElement.order = data
    if _currentName == "offset": 
        _currentElement.offset = data
        

def GetProjects(dir="."):
    """Get a list of projects accessible from the current working directory."""

    parser = xml.parsers.expat.ParserCreate()
    parser.StartElementHandler = _xmlStartElement
    parser.EndElementHandler = _xmlEndElement
    parser.CharacterDataHandler = _xmlElementData

    global _elementStack
    global _currentElement
    global _currentName
    _elementStack = []
    _currentElement = None
    _currentName = ""

    xmlOutput = captain.shell.CaptureShell("(cd " + dir 
                                           + ";cmt show projects -xml)")
    parser.Parse(xmlOutput[0])
    return _currentElement

def GetContainer(dir="."):
    out = captain.shell.CaptureShell("(cd " + dir + ";cmt show container)")
    container = Package()
    # Check for warning messages.
    for line in out[1].splitlines():
        if 0 < line.find("No container specified"): return None
        if 0 < line.find("No project found"): return None
        if line.find(" container ") < 0: continue
        line = line[line.find("container"):]
        if line.find(" not found"): line = line[:line.find(" not found")]
        parsedLine = line.split()
        container.name = parsedLine[1]
        if len(parsedLine) > 2: container.version = parsedLine[2]
        return container
    # Check for normal output.
    for line in out[0].splitlines():
        if line.find("container") < 0: continue
        line = line[line.find("container"):]
        if line.find(" not found"): line = line[:line.find(" not found")]
        parsedLine = line.split()
        container.name = parsedLine[1]
        if len(parsedLine) > 2: container.version = parsedLine[2]
        return container
    return None

def GetUses(dir="."):
    """Get a list of the packages used by the present one"""

    parser = xml.parsers.expat.ParserCreate()
    parser.StartElementHandler = _xmlStartElement
    parser.EndElementHandler = _xmlEndElement
    parser.CharacterDataHandler = _xmlElementData

    global _elementStack
    global _currentElement
    global _currentName
    _elementStack = []
    _currentElement = None
    _currentName = ""

    xmlOutput = captain.shell.CaptureShell("(cd " + dir 
                                           + ";cmt show uses -xml)")
    parser.Parse(xmlOutput[0])
    return _currentElement

def GetMissing(dir="."):
    """Get a list of the missing packages used by the present one"""

    output = captain.shell.CaptureShell("(cd " + dir + ";cmt show uses)")

    missingList = []
    for line in output[1].splitlines():
        if line.find("#CMT")<0: continue
        if line.find("Warning:")<0: continue
        line = line[line.rfind("found:")+7:]
        line = line[:line.find("(")]
        parsedLine = line.split()
        package = Package()
        package.name = parsedLine[0]
        if len(parsedLine) > 1: package.version = parsedLine[1]
        if len(parsedLine) > 2: package.offset = parsedLine[2]
        missingList.append(package)

    return missingList

def GetMissingProjects(dir="."):
    """Get a list of the missing packages used by the present one"""

    output = captain.shell.CaptureShell("(cd " + dir + ";cmt show projects)")

    missingList = []
    for line in output[1].splitlines():
        if line.find("#CMT")<0: continue
        if line.find("Warning:")<0: continue
        line = line[line.rfind("found:")+7:]
        line = line[line.find("Warning: Project"):line.find("requested by")]
        parsedLine = line.split()
        project = Project()
        project.name = parsedLine[2]
        if len(parsedLine) > 3: project.version = parsedLine[3]
        missingList.append(project)

    return missingList

def GetMacroValue(macro,dir="."):
    """Get the value of a CMT macro."""
    output = captain.shell.CaptureShell(
        "(cd " + dir 
        + "; cmt show macro_value " + macro + ")")
    if output[0] == "": return None
    value = output[0].splitlines()[0]
    return value

def GetPackage(dir="."):
    """Get information about the current package."""
    if not CheckCMT(): return None

    package = Package()

    package.name = GetMacroValue("package", dir=dir)
    if package.name == "cmt_standalone": return None

    package.version = GetMacroValue("version", dir=dir)
    package.offset = GetMacroValue(package.name + "_offset", dir=dir)
    package.root =  GetMacroValue(package.name + "_root", dir=dir)
    package.cmtpath =  GetMacroValue(package.name + "_cmtpath", dir=dir)
    package.uses = GetUses(dir)
    return package

def GetProject(dir="."):
    """Get information about the current package."""
    if not CheckCMT(): return None

    for project in GetProjects(dir):
        print project
        if project.current: return project

    return None

def CheckCMT():
    """ Check if CMT is available."""

    foundVersion = False
    try:
        cmtVersion = captain.shell.CaptureShell("cmt version")
        for line in cmtVersion[0].splitlines():
            if (re.compile(r'v(\d+)r(\d+)').match(line)):
                foundVersion = True
    except:
        foundVersion = False

    return foundVersion


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
# This provide the classes
#
# captain.cmt.Project -- A pure data class with fields for
#    type -- String with value "project". Just says what the class is.
#          This is in both the Project and Package classes
#    name -- The name of the project.
#    version -- The version string for the project.  This is derived
#          from the subdirectory containing the project.
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
#     cmtpath -- The root of the path that would be set inside the project.
#     order -- ?? Defined by CMT, but I'm not sure what it is.
#

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
        self.name = ""
        self.version = ""
        self.cmtpath = ""
        self.uses = []
        self.clients = []
        self.order = ""

    def __repr__(self):
        rep = "<project"
        rep = rep + " n: " + str(self.name)
        rep = rep + " v: " + str(self.version)
        rep = rep + " p: " + str(self.cmtpath)
        rep = rep + " u: " + str(self.uses)
        rep = rep + " c: " + str(self.clients)
        rep = rep + " O: " + str(self.order)
        rep = rep + ">"
        return rep

class Package:
    """A container for a CMT package description  The fields are:

    type -- String with value "package". Just says what the class is.
          This is in both the Project and Package classes

    name -- The name of the project.

    version -- The version string for the project.  This is derived
          from the subdirectory containing the project.

    offset -- The subdirectory that contains the package.

    root -- The package root.

    cmtpath -- The root of the path that would be set inside the project.

    order -- ?? Defined by CMT, but I'm not sure what it is.

"""
    def __init__(self):
        self.type = "package"
        self.name = ""
        self.offset = ""
        self.root = ""
        self.version = ""
        self.cmtpath = ""
        self.clients = []
        self.order = ""

    def __repr__(self):
        rep = "<package"
        rep = rep + " n: "
        if self.offset != "": rep = rep + self.offset + "/"
        rep = rep + self.name
        rep = rep + " v: " + str(self.version)
        rep = rep + " r: " + str(self.root)
        rep = rep + " p: " + str(self.cmtpath)
        rep = rep + " O: " + str(self.order)
        rep = rep + ">"
        return rep

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
        _elementStack.append(_currentElement);
    elif name == "package":
        _currentElement = Package()
        _elementStack.append(_currentElement);
    elif name == "projects":
        _currentElement = []
        _elementStack.append(_currentElement);
    elif name == "uses":
        _currentElement = []
        _elementStack.append(_currentElement);
    elif name == "clients":
        _currentElement = []
        _elementStack.append(_currentElement);

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
        elem = _elementStack.pop();
        if len(_elementStack)>0:
            _currentElement = _elementStack[-1]
            _currentElement.uses = elem
        else:
            _currentElement = elem
    elif name == "clients":
        elem = _elementStack.pop();
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

    xmlOutput = captain.shell.CaptureShell("(cd " + dir + ";cmt show projects -xml)",);
    parser.Parse(xmlOutput[0])
    return _currentElement

    
def GetUses(dir="."):
    """Get a list of the packages used by the present one"""

    parser = xml.parsers.expat.ParserCreate()
    parser.StartElementHandler = _xmlStartElement
    parser.EndElementHandler = _xmlEndElement
    parser.CharacterDataHandler = _xmlElementData

    xmlOutput = captain.shell.CaptureShell("(cd " + dir + ";cmt show uses -xml)");
    parser.Parse(xmlOutput[0])
    return _currentElement

def GetMissing(dir="."):
    """Get a list of the missing packages used by the present one"""

    output = captain.shell.CaptureShell("(cd " + dir + ";cmt show uses)");

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

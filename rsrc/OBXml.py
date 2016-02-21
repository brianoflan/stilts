
# # DEBUG1 for printed debug info
# DEBUG1=True
DEBUG1=True
# # DEBUG2 for .debug and .obxml.xml files
DEBUG2=True

# print "Python running bin OBXml.py"
# print "Python running bin OBXml.py" if DEBUG1 == True # Didn't work.
if DEBUG1: print "Python running bin OBXml.py"
# Preserves whitespace except for text of <ul> and <branches>

import codecs
import io
import xml.etree.ElementTree as ET
import os.path
from xml.sax.saxutils import escape, unescape
import random
import re
import sys
import errno
import shutil
from pprint import pprint
import ConfigParser
import StringIO
import os

if DEBUG1: print "cwd " + os.getcwd()

# infile='serialParallel.txt.xml'
infile=sys.argv[1]
if DEBUG1: print "infile " + infile
indir=''
outdir=''
reldir=''
cfgFile=''
fo=None
fo2=None
fo3=None
ulLabel=1
defaultOrderer='random' # random, straight, reverse
# defaultBrancher='random'
defaultBrancher='default' # default, random, first, last
bDefaultField='defaultField'
bWrongBranch=False

bImprobableValue='OBXml_bImprobableValue_forDefault'
# Try to remember not to use this as an actual branch value.
#  If you do it will confuse itself with any default value
#  that may exist for such a branching.

#config={'order':{}, 'branch':{'howToSayThree':'Free'}} 
# X X X XXX Load config from some kind of file.
config={}

#indent=2
# # Remove indent (why do we have indent?)

def getArgs():
    global indir, outdir, reldir, cfgFile
    if len(sys.argv) == 3:
      cfgFile=sys.argv[2]
    if len(sys.argv) > 3:
      indir=sys.argv[2]
      outdir=sys.argv[3]
      #print "indir " + indir
      #print "outdir " + outdir
      reldir=os.path.dirname(infile)
      #print "reldir before " + reldir
      re1=re.compile(re.escape(indir))
      reldir = re1.sub(outdir,reldir,count=1)
      # print "reldir after " + reldir
    else:
      reldir=os.path.dirname(infile)
    if len(sys.argv) == 5:
      cfgFile=sys.argv[4]
    if cfgFile=='':
      if DEBUG1: print "Trying env var OBXML_CONFIG " + os.environ.get('OBXML_CONFIG')
      getCfgFileArg(os.environ.get('OBXML_CONFIG'))
    # if cfgFile=='':
      # if DEBUG1: print "Trying infile " + infile + " plus .obxml.cfg"
      # getCfgFileArg(infile + '.obxml.cfg')
    if cfgFile=='':
      if DEBUG1: print "Trying dirname of infile " + infile
      getCfgFileArg(os.path.dirname(infile))
    if cfgFile=='':
      if DEBUG1: print "Trying dirname's config subdir for infile " + infile
      getCfgFileArg(os.path.join(os.path.dirname(infile),'config'))
    if DEBUG1: print "cfgFile " + cfgFile

def getCfgFileArg(cfgFileX):
    if DEBUG1: print "  Trying cfgFileX " + cfgFileX + " (getCfgFileArg)"
    global cfgFile
    # print "Trying cfgFile " + cfgFileX
    # if os.path.isdir(cfgFileX):
      # print "It's a dir."
    if cfgFileX==None:
      return()
    if os.path.isfile(cfgFileX):
      cfgFile=cfgFileX
      if DEBUG1: print "Found cfgFile: " + cfgFile
    elif os.path.isdir(cfgFileX):
      getCfgFileArg(os.path.join(cfgFileX,'OBXml.cfg'))
      
def loadConfig():
    global config
    getCfgFileArg(cfgFile)
    ini_str = '[root]\n' + open(cfgFile, 'r').read()
    ini_fp = StringIO.StringIO(ini_str)
    configX = ConfigParser.RawConfigParser()
    configX.optionxform=str
    configX.readfp(ini_fp)
    if not( 'branch' in config):
      config['branch']={}
      config['order']={}
    re3=re.compile(r'^order\.')
    re2=re.compile(r'^branch\.')
    for option in configX.options('root'):
      v=configX.get('root',option)
      if re2.match(option):
        # config['branch'][option]=re2.sub('',v)
        config['branch'][re2.sub('',option)]=v
      elif re3.match(option):
        if DEBUG1: print "'" + option + "' doesn't match '^branch\.'"
        # config['order'][option]=re3.sub('',v)
        config['order'][re3.sub('',option)]=v
      else:
        if DEBUG1: print "'" + option + "' doesn't match '^branch\.'"
        if DEBUG1: print "'" + option + "' doesn't match '^order\.'"
        config[option]=v
    
def init():
  global config
  if (not ('order' in config)):
    config['order'] = {}
  if (not ('branch' in config)):
    config['branch'] = {}
  if (not ('howToSayThree' in config['branch'])):
    config['branch']['howToSayThree'] = 'Free'
  if (not ('brancher' in config)):
    config['brancher'] = defaultBrancher
  if (not ('orderer' in config)):
    config['orderer'] = defaultOrderer

def main():
    global fo, fo2, fo3
    mkdir_p(reldir)
    
    outfile = os.path.join(reldir, os.path.basename(os.path.splitext(infile)[0]))
    outfile2 = outfile + '.obxml.xml'
    if infile == outfile:
      outfile = outfile + '.obxml.out'
    outfile3 = outfile + '.debug'
    if DEBUG2:
      print "infile " + infile
      print "outfile " + outfile
      print "outfile2 " + outfile2
      print "outfile3 " + outfile3
    
    try:
      # tree = ET.parse(infile)
      # tree = ET.parse( io.open(infile, encoding='utf-8', mode='rb') )
      tree = ET.parse( io.open(infile, mode='rb') )
    except ET.ParseError as exc:
      print "ET.ParseError exception parsing infile:"
      print exc
      shutil.copy(infile, outfile)
      return
      
    #tree2=ET.fromstring('<OBXml></OBXml>')
    root = tree.getroot()
    #root2=tree2.getroot()
    root2=ET.fromstring('<OBXml></OBXml>')
    root2.tail=root.tail
    
    if DEBUG2: fo3 = codecs.open(outfile3, encoding='utf-8', mode='w')
    fo = codecs.open(outfile, encoding='utf-8', mode='w')
    #root.text = re.sub(r'^[ \t]*(\r|\n|\r\n)[ \t]*','',root.text,count=1)
    #root2.text = "\n" 
    obxml(root,root2)
    #obxml_write(fo,root2)
    if (root.tail != None):
      fo.write(root.tail)
    fo.close()
    if DEBUG2: fo3.close()
    
    if DEBUG2:
      #tree2.write(outfile2)
      fo2 = codecs.open(outfile2, encoding='utf-8', mode='w')
      fo2.write(ET.tostring(root2))
      fo2.close()
    

def obxml(elem,elem2,nestedXml=False):
    # global indent
    global ulLabel
    # fo.write(unescape(elem.text))
    # fo.write(unescape(elem.text.lstrip().rstrip()))
    #print "elem.text " + elem.text
    #lstrip1=re.sub(r'[ \t]*(\r|\n|\r\n)[ \t]*$','',unescape(elem.text),count=1)
    lstrip1=''
    if elem.text != None:
      lstrip1=unescape(elem.text)
      if elem2.text == None:
        elem2.text = ''
      elem2.text+=elem.text
    #print "rstrip1 " + rstrip1
    #lstrip1=re.sub(r'^ *\r?\n +','',rstrip1,count=1)
    #print "lstrip1 " + lstrip1
    if not bWrongBranch:
      fo.write(lstrip1)
      if DEBUG2: fo3.write('<obxml><text>'+lstrip1+'</text>')
    #implicitp=None
    # indent += 2
    for child in elem:
      if child.tag == 'olli':
        #if implicitp != None:
          child2=ET.SubElement(elem2,'olli')
          #child2.tail="\n" + ' ' * indent
          #print "olli child.text before " + child.text + '(end)'
          #child.text=re.sub(r'(\r|\n|\r\n)[ \t]*$',r'\g<1>\n',child.text)
          #print "olli child.text after " + child.text + '(end)'
          obxml(child,child2)
          #child.tail=re.sub(r'^[ \t]*(\r|\n|\r\n)[ \t]*','',child.tail,count=1)
        #else:
          
      elif child.tag == 'branches':
        field=bDefaultField
        if child.get('field') is not None:
          field=child.get('field')
        child2=ET.SubElement(elem2,'branches',attrib={'field': field})
        child2.text="\n"
        obxmlb(child,child2,field)
          
      elif child.tag == 'obxmlul':
        label='p'+str(ulLabel).zfill(3)
        if child.get('label') is not None:
          label= child.get('label')
        else:
          ulLabel += 1
        # print "Unordered list has label " + str(label)
        child2=ET.SubElement(elem2,'obxmlul',attrib={'label': label})
        child2.text="\n"
        obxmlp(child,child2,label)
      #elif child.tag == 'li':
        #print "Unordered list item"
        #implicitp=True
      #if child.tail != None:
        # fo.write(unescape(child.tail.rstrip()))
        #tailX=re.sub(r'[ \t]*(\r|\n|\r\n)[ \t]*$','',unescape(child.tail))
        #tailX=unescape(child.tail)
        #fo.write(tailX)
        #if DEBUG2: fo3.write('<tail>'+tailX+'</tail>')
      else:
        if DEBUG1: print "Nested XML: " + child.tag
        child2=ET.SubElement(elem2,child.tag,child.attrib)
        child2.tail=child.tail
        emptyElement=True
        for grandkid in child:
          emptyElement=False
        if child.text != None:
          emptyElement=False
        if not bWrongBranch:
          outstr="<" + child.tag 
          for attribX in sorted(child.keys()):
            outstr += " " + attribX + '="' + child.get(attribX) + '"'
          if emptyElement:
            # outstr +="/>" + child.tail
            outstr +="/>"
            if not( child.tail is None ):
              outstr=outstr + child.tail
          else:
            outstr +=">"
          fo.write(outstr)
          if DEBUG2: fo3.write(outstr)
        if not(emptyElement):
          nestedXml=True
          obxml(child,child2,nestedXml)
          if not bWrongBranch:
            # outstr="</" + child.tag + ">" + child.tail
            outstr="</" + child.tag + ">"
            if not( child.tail is None ):
              outstr=outstr + child.tail
            fo.write(outstr)
            if DEBUG2: fo3.write(outstr)
        
    writeTail(elem,elem2,nestedXml)
    # indent -= 2
    if not bWrongBranch:
      if DEBUG2: fo3.write('</obxml>')

def writeTail(elem,elem2,nestedXml=False):
    if nestedXml:
      if DEBUG1: print "writeTail nestedXml! " + elem.tag
    # # li elements must come along with their tail (usually a newline)?
    # # Nonsense!
    if (elem.tail != None) and (elem.tag != 'branch') and (elem.tag != 'li'):
    # if (elem.tail != None) and (elem.tag != 'branch'):
      elem2.tail = elem.tail
      if bWrongBranch or nestedXml:
        if DEBUG1: print "Not printing tail because either wrong branch or nestedXml."
        pass
      else:
        tailX=unescape(elem.tail)
        fo.write(tailX)
        if DEBUG2: fo3.write('<tail>'+tailX+'</tail>')
    
def obxmlb(elem,elem2,field):
    global config, bWrongBranch
    if DEBUG1: pprint(config)
    # value_dict={}
    branch_dict={}
    branch_dict2={}
    #defaultBranch=None
    #defaultBranch2=None
    firstB=None
    lastB=None
    for child in elem:
      v=child.get('value')
      child2=None
      if v == None:
        v=bImprobableValue
        child2=ET.SubElement(elem2,'branch')
        #defaultBranch=child
        #defaultBranch2=child2
      else:
        child2=ET.SubElement(elem2,'branch',attrib={'value':v})
      child2.tail="\n"
      branch_dict[v]=child
      branch_dict2[v]=child2
      # value_dict[v]=1
      lastB = v
      if firstB == None:
        firstB = v
    # if (not (field in config['branch'])) or (not (field in branch_dict)):
    if (not (field in config['branch'])):
      if DEBUG1: print "Failed to find field " + field + " in config['branch'] ."
      if ('random' == config['brancher']):
        v=random.choice(branch_dict.keys())
        if DEBUG1: print "Hurray random!  " + v
      elif ('first' == config['brancher']):
        v=firstB
      elif ('last' == config['brancher']):
        v=lastB
      else: # Covers 'default' and whatnot
        v=bImprobableValue
      config['branch'][field]=v
    elif (not (config['branch'][field] in branch_dict)):
      # print "Failed to find value " + str(config['branch'][field]) + " among these values ."
      if DEBUG1: print "Failed to find value " + config['branch'][field] + " among these values ."
      v=bImprobableValue
    else:
      v=str(config['branch'][field])
    bWrongBranch=True
    for x in branch_dict.keys():
      if x==v:
        bWrongBranch=False
      obxml(branch_dict[x],branch_dict2[x])
      bWrongBranch=True
    if DEBUG1: print "field " + field + " v " + v
    bWrongBranch=False
    writeTail(elem,elem2)

def obxmlp(elem,elem2,label):
    global config
    max_i=0
    order_dict={}
    elem_dict={}
    elem_dict2={}
    order=[]
    for child in elem:
      i=child.get('i')
      if i == None:
        i=max_i+1
      i=int(i)
      max_i=max(i,max_i)
      #print "li " + str(i)
      child2=ET.SubElement(elem2,'li',attrib={'i':str(i)})
      
      # XXX?
      child2.tail="\n"
      
      order_dict[i]=1
      order.append(i)
      elem_dict[str(i)]=child
      # print "elem_dict[i] " + str(i) + " " + str(elem_dict[i])
      elem_dict2[str(i)]=child2
    order_str=''
    if not(label in config['order']):
      if DEBUG1: print "Found no order for " + label
      if ('straight' == config['orderer']):
        order_str=','.join(map((lambda y: str(y)), order))
      elif ('reverse' == config['orderer']):
        order_str=','.join(map((lambda y: str(y)), reversed(order)))
      else: # Covers 'random' and whatnot
        order=[]
        while order_dict.keys():
          x=random.choice(order_dict.keys())
          order.append(x)
          del order_dict[x]
        order_str=','.join(map((lambda y: str(y)), order))
        if DEBUG1: print "Hurray random!  " + order_str
      config['order'][label]=order_str
    order_str=config['order'][label]
    if DEBUG1: print "Order for " + label + " = " + order_str
    for j in re.split('[,\s]',order_str):
      #print "Order " + j
      a=elem_dict[j]
      b=elem_dict2[j]
      obxml(a,b)
    writeTail(elem,elem2)

#
   
def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc: # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else: raise
        
#
getArgs()
loadConfig()
init()
main()

#

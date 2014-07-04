/*
 * $Id: mgide.prg,v 1.8 2014-07-04 20:16:02 fyurisich Exp $
 */

#include "oohg.ch"
#include "hbclass.ch"
#include "common.ch"
#include "i_keybd.ch"

#DEFINE CRLF hb_OSNewLine()
#DEFINE CR chr(13)
#DEFINE LF chr(10)
#DEFINE HTAB chr(9)
#DEFINE cNameApp "Harbour ooHG IDE Plus"+" v."+substr(__DATE__,3,2)+"."+right(__DATE__,4) // MigSoft

#ifdef __HARBOUR__
   #xtranslate Curdrive() => hb_Curdrive()    // MigSoft
#endif

//------------------------------------------------------------------------------
Function Main( rtl1 )
//------------------------------------------------------------------------------
   Public nhandlep    := 0
   Public whlp        := ''
   Public myform
   Public exedir      := ''
   Public rtl         := rtl1
   Public mgideFolder := GetStartupFolder()
   Public pmgFolder   := ''

   SetAppHotKey( VK_F10, 0, { || _OOHG_CallDump() } )
   SetAppHotKey( VK_F11, 0, { || AutoMsgBox( &( InputBox( "Variable to inspect:", "ooHG IDE+" ) ) ) } )

   If rtl # NIL
      rtl := Upper( rtl )
      If rtl == "RTL"
         SET GLOBALRTL ON
         rtl := NIL
      EndIf
   EndIf

   Public myIde := THMI()
   myIde:NewIde( rtl )
RETURN NIL


//------------------------------------------------------------------------------
CLASS THMI
//------------------------------------------------------------------------------
   VAR cfile              INIT ''
   VAR cprojectname       INIT ''
   VAR cHelpFolder        INIT ''
   VAR cProjFolder        INIT ''
   VAR cOutFile           INIT ''

   VAR cExteditor         INIT ''

   VAR cGuiHbBCC          INIT ''
   VAR cGuiHbMinGW        INIT ''
   VAR cGuiHbPelles       INIT ''

   VAR cGuixHbBCC         INIT ''
   VAR cGuixHbMinGW       INIT ''
   VAR cGuixHbPelles      INIT ''

   VAR cHbBCCFolder       INIT ''
   VAR cHbMinGWFolder     INIT ''
   VAR cHbPellFolder      INIT ''

   VAR cxHbBCCFolder      INIT ''
   VAR cxHbMinGWFolder    INIT ''
   VAR cxHbPellFolder     INIT ''

   VAR cBCCFolder         INIT ''
   VAR cMinGWFolder       INIT ''
   VAR cPellFolder        INIT ''

   VAR nCompxBase         INIT 1
   VAR nCompilerC         INIT 2

   VAR ltbuild            INIT 1
   VAR lsnap              INIT 0
   VAR clib               INIT ""

   VAR asystemcolor       INIT {215,231,244}
   VAR asystemcoloraux    INIT  {}
   VAR swvan              INIT .F.
   VAR swsalir            INIT .F.
   VAR lPsave             INIT .T.
   VAR _ncaretpos         INIT  0
   VAR alinet             INIT {}
   VAR lsave              INIT .T.
   VAR npostext           INIT 0
   VAR ncrlf              INIT 0
   VAR van                INIT 0
   VAR ctext              INIT ''
   VAR ntemp              INIT 0
   VAR cdbackcolor        INIT 'NIL'

   VAR aliner             INIT {}
   VAR lvirtual           INIT .T.

   VAR mainheight         INIT 50 + GetTitleHeight() + GetBorderHeight()
   VAR form_activated     INIT .F.

   METHOD NewIde()
   METHOD exit()
   METHOD deleteitemp()
   METHOD printit()
   METHOD about()
   METHOD dataman()
   METHOD splashdelay()
   METHOD preferences()
   METHOD okprefer()
   METHOD searchtext()
   METHOD BldMinGW( nOption )
   METHOD BuildBcc( nOption )
   METHOD BldPellC( nOption )
   METHOD xBldMinGW( nOption )
   METHOD xBuildBCC( nOption )
   METHOD xBldPellC( nOption )
   METHOD viewsource( wr )
   METHOD viewerrors( wr )
   METHOD runp()
   METHOD newproject()
   METHOD openproject()
   METHOD saveproject()

   METHOD newform()
   METHOD newformfromar(cPform)
   METHOD Newprgfromar(cPprg)
   METHOD Newchfromar(cPch)
   METHOD Newrcfromar(cPrc)
   METHOD Newrptfromar(cPrpt)

   METHOD Newprg()
   METHOD Newch()
   METHOD Newrc()
   METHOD Newrpt()

   METHOD searchitem(cnameitem,cparent)
   METHOD searchtypeadd(nvalue)
   METHOD searchtype()
   METHOD modifyitem()
   METHOD modifyRpt()
   METHOD modifyform()

   METHOD savefile(cdfile)
   METHOD Openfile(cdfile)
   METHOD goline()
   METHOD lookchanges()
   METHOD posxy()
   METHOD txtsearch()
   METHOD nextsearch()
   METHOD saveandexit(cdfile)
   METHOD databaseview()
   METHOD exitview()
   METHOD disable_button()
   METHOD exitform()

ENDCLASS
RETURN NIL

*-------------------------
METHOD NewIde( rtl) CLASS THMI
*-------------------------
local i,npos,capellido,cnombre, nRed, nGreen, nBlue
public csyscolor,cvccvar

   SET CENTURY ON
   SET EXACT ON
   SET INTERACTIVECLOSE OFF
   SET NAVIGATION EXTENDED
   SET BROWSESYNC ON

   DECLARE WINDOW Form_Tree
   DECLARE WINDOW form_prefer
   DECLARE WINDOW form_main
   DECLARE WINDOW _errors
   DECLARE WINDOW editbcvc
   DECLARE WINDOW form_brow
   DECLARE WINDOW cvcControls
   DECLARE WINDOW waitmess
   DECLARE WINDOW form_splash

   ::cHelpFolder := GetStartupFolder()
   exedir := mgidefolder                          // MigSoft
   lCorre := .F.   ///// no es proyecto

   if rtl#NIL .and. rtl#"RTL"
      rtl:=lower(rtl)
      npos:=at(".",rtl)
      if npos>0
         capellido := substr(rtl,npos+1,3)
         cnombre   := substr(rtl,1,npos-1)
         if lower(capellido)="pmg"
            lcorre := .T.
         endif
      endif
   else
      if file(exedir)
         cvccvar:=alltrim(memoread(exedir))
         dirchange(cvccvar)
      endif
   endif

   nesquema := 4
   nRed     := GETRED(GETSYSCOLOR(nesquema))
   nGreen   := GETGREEN(GETSYSCOLOR(nesquema))
   nBlue    := GETBLUE(GETSYSCOLOR(nesquema))

   csyscolor :='{'+str(nred,3)+','+str(ngreen,3)+','+str(nblue,3)+'}'
   ::asystemcoloraux := &csyscolor
   cvcx :=getdesktopwidth()
   cvcy :=getdesktopheight()

   if cvcx<800 .or. cvcy<600
      MsgInfo( 'Best viewed with 800x600 or greater resolution.', 'ooHG IDE+' )
   endif

*-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._-._.-._.-._.-._.-._.-._.-._
*                      Main Window -  760 x 500   30,134
*-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._-._.-._.-._.-._.-._.-._.-._

   DEFINE WINDOW Form_Tree OBJ Form_Tree ;
      AT 0,0 ;
      WIDTH 800 ;
      HEIGHT 600 ;
      TITLE cNameApp ;
      MAIN ;
      FONT "Times new Roman" SIZE 11 ;
      ICON "Edit" ;
      ON SIZE AjustaFrame(oFrame,oTree) ;     // MigSoft
      ON INTERACTIVECLOSE If( MsgYesNo( "Exit program?", 'ooHG IDE+' ), ::exit(), .F. ) ;
      NOSHOW ;
      BACKCOLOR ::asystemcolor

      DEFINE STATUSBAR FONT "Verdana" SIZE 9       // MigSoft
         STATUSITEM cNameApp+"                                 F1 Help    F5 Build    F6 Build / Run    F7 Run    F8 Debug"
      END STATUSBAR

      DEFINE MAIN MENU
         POPUP '&File'
            ITEM '&New project ' ACTION ::newproject()
            ITEM '&Open Project' ACTION ::openproject()
            ITEM '&Save Project' ACTION ::saveproject()
            SEPARATOR
            ITEM '&Preferences' ACTION ::preferences()
            SEPARATOR
            ITEM '&Exit' ACTION ::exit()
         END POPUP
         POPUP 'Pro&ject'
            POPUP 'Add' NAME 'Add'                    // MigSoft
               ITEM 'Form ' ACTION ::newform()
               ITEM 'Prg  ' ACTION ::newprg()
               ITEM 'CH   ' ACTION ::newch()
               ITEM 'Rpt  ' ACTION ::newrpt()
               ITEM 'RC   ' ACTION ::newrc()
            END POPUP
            SEPARATOR
            ITEM "Modify item" Action analizar( Self )
            SEPARATOR
            ITEM 'Remove Item' ACTION ::deleteitemp()
            SEPARATOR
            ITEM 'View / Print Item' ACTION ::printit()
         END POPUP
         POPUP 'Build / Run / Debug'
            ITEM 'Build Project'         ACTION CompileOptions( Self, 1 )
            ITEM 'Build and Run Project' ACTION CompileOptions( Self, 2 )
            ITEM 'Run Project'           ACTION CompileOptions( Self, 3 )
            ITEM 'Debug Project'         ACTION CompileOptions( Self, 4 )
         END POPUP
         POPUP 'Tools'
            ITEM 'Global Search Text'  ACTION ::searchtext()
            ITEM 'Quickbrowse'  ACTION ::databaseview()
            ITEM 'Data Manager'  ACTION ::dataman()
         END POPUP

         POPUP '&Help'
            ITEM 'ooHG Syntax Help' ACTION _Execute( GetActiveWindow(), Nil, ::cHelpFolder + "\oohg.chm", Nil, Nil, 5 )
            ITEM '&About' ACTION ::about()
            ITEM 'Shell info' ACTION shellabout(cNameApp,"Shell info")
         END POPUP
      END MENU

      ON KEY F1 action help_f1('PROJECT')
      ON KEY F5 action CompileOptions( Self, 1 )
      ON KEY F6 action CompileOptions( Self, 2 )
      ON KEY F7 action CompileOptions( Self, 3 )
      ON KEY F8 action CompileOptions( Self, 4 )

      @ 65,30 frame frame_tree OBJ oFrame width cvcx-30  height cvcy-65

      DEFINE TREE Tree_1 OBJ oTree AT 90,50 WIDTH 200 HEIGHT cvcy-290 VALUE 1 ;   // MigSoft
         TOOLTIP 'Double click to modify items'   ;
         ON DBLCLICK analizar( Self ) ;
         NODEIMAGES { "cl_fl", "op_fl"};
         ITEMIMAGES { "doc", "doc_fl" };

         NODE 'Project'  IMAGES { "doc" }
            TREEITEM 'Form module'
            TREEITEM 'Prg module'
            TREEITEM 'CH module'
            TREEITEM 'Rpt module'
            TREEITEM 'RC module'
         END NODE

      END TREE

      DEFINE SPLITBOX
         DEFINE TOOLBAR ToolBar_1y BUTTONSIZE 16,16 FLAT ;
            FONT 'Times new roman' SIZE 10 ITALIC

            BUTTON Button_13 ;
            TOOLTIP 'Exit ' ;
            PICTURE 'M1';
            ACTION If( MsgYesNo( "Exit program?", 'ooHG IDE+' ), ::exit(), Nil ) AUTOSIZE

            BUTTON Button_1 ;
            TOOLTIP 'New...' ;
            PICTURE 'M2';
            ACTION ::newform() DROPDOWN AUTOSIZE

            BUTTON Button_1b ;
            TOOLTIP 'Open...' ;
            PICTURE 'M3';
            ACTION ::openproject() AUTOSIZE

            BUTTON Button_01 ;
            TOOLTIP 'Save...' ;
            PICTURE 'M4';
            ACTION ::saveproject() AUTOSIZE

            BUTTON Button_7 ;
            TOOLTIP 'Remove Item' ;
            PICTURE 'M5' ;
            ACTION ::deleteitemp() AUTOSIZE

            BUTTON Button_7a ;
            TOOLTIP 'View / Print Item' ;
            Picture 'M6' ;
            ACTION ::printit() separator AUTOSIZE

            BUTTON Button_9 ;
            TOOLTIP 'Build project' ;
            PICTURE 'M7';
            ACTION CompileOptions( Self, 1 )

            BUTTON Button_10 ;
            TOOLTIP 'Build / Run' ;
            PICTURE 'M8' ;
            ACTION CompileOptions( Self, 2 )

            BUTTON Button_11 ;
            TOOLTIP 'Run' ;
            PICTURE 'M9';
            ACTION CompileOptions( Self, 3 ) DROPDOWN AUTOSIZE separator

            BUTTON Button_8 ;
            TOOLTIP 'Global Search Text' ;
            PICTURE 'M10';
            ACTION ::Searchtext() separator AUTOSIZE

            BUTTON Button_qb ;
            TOOLTIP 'Quick Browse' ;
            PICTURE 'M11';
            ACTION ::databaseview() AUTOSIZE

            BUTTON Button_12 ;
            TOOLTIP 'Data Manager' ;
            PICTURE 'M12';
            ACTION ::dataman() AUTOSIZE
         END TOOLBAR

         DEFINE DROPDOWN MENU BUTTON Button_1
            ITEM 'Form'    ACTION ::newform()
            ITEM 'Prg'     ACTION ::newprg()
            ITEM 'CH'      ACTION ::newch()
            ITEM 'Rpt'     ACTION ::newrpt()
            ITEM 'RC'      ACTION ::newrc()
         END MENU

         DEFINE DROPDOWN MENU BUTTON Button_11
            ITEM 'Run  ' ACTION CompileOptions( Self, 3 )
            ITEM 'Debug' ACTION CompileOptions( Self, 4 )
         END MENU
      END SPLITBOX

      @ 135,280 image image_front OBJ image_front ;
         picture 'hmiq' ;
         width 420 ;
         height 219

      Form_Tree:tree_1:fontitalic:=.T.

      If Empty(rtl)
         Desactiva(0)  // MigSoft
      Else
         Desactiva(1)  // MigSoft
      Endif
   END WINDOW

   DEFINE WINDOW Form_Splash obj Form_splash ;
      AT 0,0 ;
      WIDTH 584 HEIGHT 308 ;
      TITLE '';
      MODAL TOPMOST NOCAPTION ;
      ON INIT ::SplashDelay() ;

      @ 0,0 IMAGE image_splash PICTURE 'hmi'  ;
         WIDTH 584 ;
         HEIGHT 308
   END WINDOW

   CENTER WINDOW Form_Splash
   CENTER WINDOW Form_Tree

   IF .NOT. FILE('hmi.INI')
      a := MemoWrit('hmi.INI','[PROJECT]')
   ENDIF

   BEGIN INI FILE 'hmi.INI'
      //****************** PROJECT
      GET ::cProjFolder     SECTION 'PROJECT'  ENTRY "PROJFOLDER"    default ''      // MigSoft
      GET ::cOutFile        SECTION 'PROJECT'  ENTRY "OUTFILE"       default ''
      //****************** EDITOR
      GET ::cExteditor      SECTION 'EDITOR'   ENTRY "EXTERNAL"      default ''
      //****************** OOHG
      GET ::cGuiHbMinGW     SECTION 'GUILIB'   ENTRY "GUIHBMINGW"    default 'c:\oohg'
      GET ::cGuiHbBCC       SECTION 'GUILIB'   ENTRY "GUIHBBCC"      default 'c:\oohg'
      GET ::cGuiHbPelles    SECTION 'GUILIB'   ENTRY "GUIHBPELL"     default 'c:\oohg'
      GET ::cGuixHbMinGW    SECTION 'GUILIB'   ENTRY "GUIXHBMINGW"   default 'c:\oohg'
      GET ::cGuixHbBCC      SECTION 'GUILIB'   ENTRY "GUIXHBBCC"     default 'c:\oohg'
      GET ::cGuixHbPelles   SECTION 'GUILIB'   ENTRY "GUIXHBPELL"    default 'c:\oohg'
      //****************** HARBOUR
      GET ::cHbMinGWFolder  SECTION 'HARBOUR'  ENTRY "HBMINGW"       default 'c:\harbourm'
      GET ::cHbBCCFolder    SECTION 'HARBOUR'  ENTRY "HBBCC"         default 'c:\harbourb'
      GET ::cHbPellFolder   SECTION 'HARBOUR'  ENTRY "HBPELLES"      default 'c:\harbourp'
      //****************** XHARBOUR
      GET ::cxHbMinGWFolder SECTION 'HARBOUR'  ENTRY "XHBMINGW"      default 'c:\xharbourm'
      GET ::cxHbBCCFolder   SECTION 'HARBOUR'  ENTRY "XHBBCC"        default 'c:\xharbourb'
      GET ::cxHbPellFolder  SECTION 'HARBOUR'  ENTRY "XHBPELLES"     default 'c:\xharbourp'
      //****************** C COMPILER
      GET ::cMinGWFolder    SECTION 'COMPILER' ENTRY "MINGWFOLDER"   default 'c:\MinGW'
      GET ::cBCCFolder      SECTION 'COMPILER' ENTRY "BCCFOLDER"     default 'c:\Borland\BCC55'
      GET ::cPellFolder     SECTION 'COMPILER' ENTRY "PELLESFOLDER"  default 'c:\PellesC'
      //****************** MODE
      GET ::nCompxBase      SECTION 'WHATCOMP' ENTRY "XBASECOMP"     default 1  // 1 Harbour  2 xHarbour
      GET ::nCompilerC      SECTION 'WHATCOMP' ENTRY "CCOMPILER"     default 1  // 1 MinGW    2 BCC   3 Pelles C
      //****************** OTHER
      GET ::ltbuild         SECTION 'SETTINGS' ENTRY "BUILD"         default 2  // 1 Compile.bat 2 Own Make
      GET ::lsnap           SECTION 'SETTINGS' ENTRY "SNAP"          default 0
      GET ::clib            SECTION 'SETTINGS' ENTRY "LIB"           default ''
   END INI

   DEFINE WINDOW waitmess obj waitmess  ;
      AT 10,10  ;
      WIDTH 150 ;
      HEIGHT 100 ;
      TITLE "Information"  CHILD NOSYSMENU NOCAPTION NOSHOW  ;
      BACKCOLOR ::asystemcolor

      @ 35,15 label hmi_label_101 value '              '  autosize font 'Times new Roman'  SIZE 14
   END WINDOW

*-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._-._.-._.-._.-._.-._.-._.-._
*                          Horizontal buttons
*-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._-._.-._.-._.-._.-._.-._.-._

   DEFINE WINDOW  Form_main ;
      AT 0,0 ;
      WIDTH 689 ;
      HEIGHT 104 ;
      TITLE '' ;
      CHILD ;
      NOSHOW  ;
      NOMAXIMIZE ;
      NOSIZE ;
      OBJ Form_main ;
      ICON "Edit" ;
      FONT 'MS Sans Serif' ;
      SIZE 10 ;
      BACKCOLOR ::asystemcolor ;
      ON MINIMIZE  minim() ;
      ON MAXIMIZE  maxim() ;
      ON RESTORE maxim()

      @ 17,10 BUTTON exit ;
         PICTURE 'A1';
         ACTION ::exitform() ;
         WIDTH 28 ;
         HEIGHT 28 ;
         TOOLTIP 'Exit' ;

      @ 17,41 BUTTON save ;
         PICTURE 'A2';
         ACTION {|| myform:Save(0) } ;
         WIDTH 30 ;
         HEIGHT 28 ;
         TOOLTIP 'Save' ;

      @ 17,73 BUTTON save_as ;
         PICTURE 'A3';
         ACTION myform:save(1) ;
         WIDTH 30 ;
         HEIGHT 28 ;
         TOOLTIP 'Save as' ;

      @ 17,112 BUTTON form_prop ;
         PICTURE 'A4';
         ACTION FrmProperties( Self ) ;
         WIDTH 30 ;
         HEIGHT 28 ;
         TOOLTIP 'Properties' ;

      @ 17,144 BUTTON events_prop ;
         PICTURE 'A5';
         ACTION FrmEvents( Self ) ;
         WIDTH 30 ;
         HEIGHT 28 ;
         TOOLTIP 'Events' ;

      @ 17,176 BUTTON form_mc ;
         PICTURE 'A6';
         ACTION IntFoco( 0, Self ) ;
         WIDTH 30 ;
         HEIGHT 28 ;
         TOOLTIP 'Fonts and Colors' ;

      @ 17,209 BUTTON tbc_fmms ;
         PICTURE 'A7';
         ACTION ManualMoSi( 0, Self ) ;
         WIDTH 30 ;
         HEIGHT 28 ;
         TOOLTIP 'Manual Move/Size' ;

      @ 17,240 BUTTON mmenu1 ;
         PICTURE 'A8';
         ACTION tMyMenu:menu_ed( 1 ) ;
         WIDTH 30 ;
         HEIGHT 28 ;
         TOOLTIP 'Main Menu' ;

      @ 17,273 BUTTON mmenu2 ;
         PICTURE 'A9';
         ACTION tMyMenu:menu_ed( 2 ) ;
         WIDTH 30 ;
         HEIGHT 28 ;
         TOOLTIP 'Context Menu' ;

      @ 17,303 BUTTON mmenu3 ;
         PICTURE 'A10';
         ACTION tMyMenu:menu_ed( 3 ) ;
         WIDTH 30 ;
         HEIGHT 28 ;
         TOOLTIP 'Notify Menu' ;

      @ 17,337 BUTTON toolb ;
         PICTURE 'A11';
         ACTION { || tMyToolb:tb_ed() } ;
         WIDTH 30 ;
         HEIGHT 28 ;
         TOOLTIP 'Toolbar' ;

      @ 17,368 BUTTON form_co ;
         PICTURE 'A12';
         ACTION OrderControl( Self ) ;
         WIDTH 30 ;
         HEIGHT 28 ;
         TOOLTIP 'Order'

      @ 17,400 BUTTON  butt_status ;
         PICTURE 'A13';
         ACTION { || myform:verifybar() } ;
         WIDTH 30 ;
         HEIGHT 28 ;
         TOOLTIP 'Statusbar On/Off' ;

      @ 17,444 BUTTON tbc_prop ;
         PICTURE 'A4';
         ACTION Properties_Click( Self ) ;
         WIDTH 30 ;
         HEIGHT 28 ;
         TOOLTIP 'Properties' ;

      @ 17,477 BUTTON tbc_events ;
         PICTURE 'A5';
         ACTION Events_Click( Self )  ;
         WIDTH 30 ;
         HEIGHT 28 ;
         TOOLTIP 'Events' ;

      @ 17,510 BUTTON tbc_ifc ;
         PICTURE 'A6';
         ACTION intfoco( 1, Self )  ;
         WIDTH 30 ;
         HEIGHT 28 ;
         TOOLTIP 'Font Color' ;

      @ 17,540 BUTTON tbc_mms  ;
         PICTURE 'A7';
         ACTION manualmosi( 1, Self )  ;
         WIDTH 30 ;
         HEIGHT 28 ;
         TOOLTIP 'Manual Move/Size' ;

      @ 17,572 BUTTON tbc_im ;
         PICTURE 'A17';
         ACTION MoveControl( Self )  ;
         WIDTH 30 ;
         HEIGHT 28 ;
         TOOLTIP 'Interactive Move' ;

      @ 17,604 BUTTON tbc_is ;
         PICTURE 'A14';
         ACTION SizeControl()  ;
         WIDTH 30 ;
         HEIGHT 28 ;
         TOOLTIP 'Interactive Size' ;

      @ 17,634 BUTTON tbc_del ;
         PICTURE 'A16';
         ACTION DeleteControl() ;
         WIDTH 30 ;
         HEIGHT 28 ;
         TOOLTIP 'Delete' ;

      @ 0,105 FRAME frame_1 ;
         CAPTION "Form : " ;
         WIDTH 332 ;
         HEIGHT 65

      form_main.frame_1.fontcolor:= { 0,0,0 }
      form_main.frame_1.fontname:="MS Sans Serif"
      form_main.frame_1.fontsize:=9

      @ 0,436 FRAME frame_2 ;
         CAPTION "Control : " ;
         WIDTH 236 ;
         HEIGHT 65 ;
         OPAQUE ;

      form_main.frame_2.fontcolor:= { 0,0,0 }
      form_main.frame_2.fontname:="MS Sans Serif"
      form_main.frame_2.fontsize:=9

      @ 0,4 FRAME frame_3 ;
         CAPTION "Action" ;
         WIDTH 105 ;
         HEIGHT 65  ;

      form_main.frame_3.fontcolor:=  { 0,0,0 }
      form_main.frame_3.fontname:="MS Sans Serif"
      form_main.frame_3.fontsize:=9

      @ 48,115 LABEL label_1 ;
         WIDTH 120 ;
         HEIGHT 24 ;
         VALUE '' ;
         FONT 'MS Sans Serif' ;
         SIZE 9  ;
         AUTOSIZE  ;

      form_main.label_1.fontcolor:=  { 0,0,0 }

      @ 48,446 LABEL label_2 ;
         WIDTH 120 ;
         HEIGHT 24 ;
         VALUE 'r:    c:    w:    h: ' ;
         FONT 'MS Sans Serif' ;
         SIZE 9  ;
         AUTOSIZE ;

      form_main.label_2.fontcolor:=  { 0,0,0 }

      @ 48,300 LABEL labelyx ;
         WIDTH 98 ;
         HEIGHT 24 ;
         VALUE '0000,0000' ;
         FONT 'MS Sans Serif' ;
         SIZE 9  ;
         AUTOSIZE ;

   END WINDOW

////ON KEY ALT+D ACTION debug()

   tMyMenu := TmyMenuEd()
   tMyMenu:cfBackcolor := ::asystemcolor
   tMyToolb := tMyToolbarEd()
   tMyToolb:Backcolor := ::asystemcolor

*-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._-._.-._.-._.-._.-._.-._.-._
*                          Vertical Checkbuttons
*-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._-._.-._.-._.-._.-._.-._.-._

public lsi := .T.   ///// variable publica que evita la recursividad del on change en el checkbutton
DEFINE WINDOW cvcControls obj cvcControls ;
   AT 120 , 0 ;
   WIDTH 65 ;
   HEIGHT 450 + GetTitleHeight() + GetBorderheight() ;
   TITLE 'Controls' ;
   ICON 'VD' ;
   CHILD NOSHOW ; // NOCAPTION ;
   NOSIZE NOMAXIMIZE ;
   NOAUTORELEASE ;
   NOMINIMIZE ;
   NOSYSMENU ;
   backcolor ::asystemcolor

   @ 001,0 CHECKBUTTON Control_01 ;
   PICTURE 'SELECT' ;
   VALUE .T. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'Select Object' ;
   ON CHANGE myform:Control_Click(1)

   @ 001,29 CHECKBUTTON Control_02 ;
   PICTURE 'BUTTON1' ;                     // Cambio en .RC
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'Button and ButtonMixed' ;
   ON CHANGE myform:Control_Click(2)

   @ 030,0 CHECKBUTTON Control_03 ;
   PICTURE 'CHECKBOX1' ;                     // Cambio en .RC
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'CheckBox' ;
   ON CHANGE myform:Control_Click(3)

   @ 030,29 CHECKBUTTON Control_04 ;
   PICTURE 'LISTBOX1' ;                     // Cambio en .RC
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'ListBox' ;
   ON CHANGE myform:Control_Click(4)

   @ 060,0 CHECKBUTTON Control_05 ;
   PICTURE 'COMBOBOX1' ;                     // Cambio en .RC
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'ComboBox' ;
   ON CHANGE myform:Control_Click(5)

   @ 060,29 CHECKBUTTON Control_06 ;
   PICTURE 'CHECKBUTTON' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'CheckButton' ;
   ON CHANGE myform:Control_Click(6)

   @ 090,0 CHECKBUTTON Control_07 ;
   PICTURE 'GRID' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'Grid' ;
   ON CHANGE myform:Control_Click(7)

   @ 090,29 CHECKBUTTON Control_08 ;
   PICTURE 'FRAME' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'Frame' ;
   ON CHANGE  myform:Control_Click(8)

   @ 120,0 CHECKBUTTON Control_09 ;
   PICTURE 'TAB' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'Tab' ;
   ON CHANGE myform:Control_Click(9)

   @ 120,29 CHECKBUTTON Control_10 ;
   PICTURE 'IMAGE' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'Image' ;
   ON CHANGE myform:Control_Click(10)

   @ 150,0 CHECKBUTTON Control_11 ;
   PICTURE 'ANIMATEBOX' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'AnimateBox' ;
   ON CHANGE myform:Control_Click(11)

   @ 150,29 CHECKBUTTON Control_12 ;
   PICTURE 'DATEPICKER' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'DatePicker' ;
   ON CHANGE myform:Control_Click(12)

   @ 180,0 CHECKBUTTON Control_13 ;
   PICTURE 'TEXTBOX' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'TextBox' ;
   ON CHANGE myform:Control_Click(13)

   @ 180,29 CHECKBUTTON Control_14 ;
   PICTURE 'EDITBOX' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'EditBox' ;
   ON CHANGE myform:Control_Click(14)

   @ 210,0 CHECKBUTTON Control_15 ;
   PICTURE 'LABEL' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'Label' ;
   ON CHANGE myform:Control_Click(15)

   @ 210,29 CHECKBUTTON Control_16 ;
   PICTURE 'PLAYER' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'Player' ;
   ON CHANGE myform:Control_Click(16)

   @ 240,0 CHECKBUTTON Control_17 ;
   PICTURE 'PROGRESSBAR' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'ProgressBar' ;
   ON CHANGE myform:Control_Click(17)

   @ 240,29 CHECKBUTTON Control_18 ;
   PICTURE 'RADIOGROUP' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'RadioGroup' ;
   ON CHANGE myform:Control_Click(18)

   @ 270,0 CHECKBUTTON Control_19 ;
   PICTURE 'SLIDER' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'Slider' ;
   ON CHANGE myform:Control_Click(19)

   @ 270,29 CHECKBUTTON Control_20 ;
   PICTURE 'SPINNER' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'Spinner' ;
   ON CHANGE myform:Control_Click(20)

   @ 300,0 CHECKBUTTON Control_21 ;
   PICTURE 'IMAGECHECKBUTTON' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'Picture CheckButton' ;
   ON CHANGE myform:Control_Click(21)

   @ 300,29 CHECKBUTTON Control_22 ;
   PICTURE 'IMAGEBUTTON' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'Picture Button' ;
   ON CHANGE myform:Control_Click(22)

   @ 330,0 CHECKBUTTON Control_23 ;
   PICTURE 'TIMER' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'Timer' ;
   ON CHANGE myform:Control_Click(23)

   @ 330,29 CHECKBUTTON Control_24 ;
   PICTURE 'GRID' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'Browse' ;
   ON CHANGE myform:Control_Click(24)

   @ 360,0 CHECKBUTTON Control_25 ;
   PICTURE 'TREE' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'Tree' ;
   ON CHANGE myform:Control_Click(25)

   @ 360,29 CHECKBUTTON Control_26 ;
   PICTURE 'IPAD' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'IPAddress' ;
   ON CHANGE myform:Control_Click(26)

   @ 390,0 CHECKBUTTON Control_27 ;
   PICTURE 'MONTHCAL' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'Monthcalendar' ;
   ON CHANGE myform:Control_Click(27)

   @ 390,29 CHECKBUTTON Control_28 ;
   PICTURE 'HYPLINK' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'Hyperlink' ;
   ON CHANGE myform:Control_Click(28)

   @ 420,0 CHECKBUTTON Control_29 ;
   PICTURE 'RICHEDIT' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'Richeditbox' ;
   ON CHANGE myform:Control_Click(29)

   @ 420,29 CHECKBUTTON Control_30 ;
   PICTURE 'stat' ;
   VALUE .F. WIDTH 28 HEIGHT 28 ;
   TOOLTIP 'StatusBar' ;
   ON CHANGE StatPropEvents( Self )

END WINDOW

CENTER WINDOW waitmess

   if lcorre
      openauxi( Self, cnombre )
      RTL := NIL
   endif


if rtl=NIL
   ACTIVATE WINDOW Form_Tree,form_main,waitmess,cvccontrols,form_splash
else
   Form_Tree.hide
   ACTIVATE WINDOW Form_Tree,form_main,waitmess,cvccontrols,form_splash nowait
   analizar( Self, rtl )
endif
Return Self

Procedure AjustaFrame(oFrame,oTree) // MigSoft
   LOCAL aInfo
   aInfo := ARRAY( 4 )
   GetClientRect( Form_Tree:hWnd, aInfo )

   oframe:width  := aInfo[ 3 ] - 65
   oframe:height := aInfo[ 4 ] - 120
   oTree:height  := oframe:height - 50

   If ( oframe:width < ( image_front:width + 270 ) ) .OR. ( oframe:height < ( image_front:height + 80 ) )
      HIDE CONTROL image_front OF Form_Tree
   Else
      SHOW CONTROL image_front OF Form_Tree
   Endif

Return

Function Desactiva(nOp)   // MigSoft
   If nOp = 0
      SetProperty('Form_Tree','Add','enabled',.F.)
      SetProperty('Form_Tree','Button_1','enabled',.F.)
    Else
      SetProperty('Form_Tree','Add','enabled',.T.)
      SetProperty('Form_Tree','Button_1','enabled',.T.)
    Endif
Return Nil

//------------------------------------------------------------------------------
Procedure BorraTemp( cProjFolder )
//------------------------------------------------------------------------------
   If File( cProjFolder + "\OBJ\nul" )
      ZapDirectory( cProjFolder + "\OBJ" + Chr(0) )
   EndIf
   FErase( cProjFolder + '_aux.rc' )
   FErase( cProjFolder + '_build.bat' )
   FErase( cProjFolder + '_oohg_resconfig.h' )
   FErase( cProjFolder + '_temp.bc' )
   FErase( cProjFolder + '_temp.rc' )
   FErase( cProjFolder + 'b32.bc' )
   FErase( cProjFolder + 'comp.bat' )
   FErase( cProjFolder + 'error.lst' )
   FErase( cProjFolder + 'makefile.gcc' )
Return

//------------------------------------------------------------------------------
Procedure BorraObj()
//------------------------------------------------------------------------------
   Local aOBJFilesB[aDir( 'OBJ\*.OBJ' )]
   Local aCFiles[aDir( 'OBJ\*.C' )]
   Local aOFiles[aDir( 'OBJ\*.O' )]
   Local aRESFiles[aDir( 'OBJ\*.RES' )]
   Local aMAPFiles[aDir( '*.MAP' )]
   Local aTDSFiles[aDir( '*.TDS' )]
   Local i

   aDir( 'OBJ\*.OBJ', aOBJFilesB )
   aDir( 'OBJ\*.C', aCFiles )
   aDir( 'OBJ\*.O', aOFiles )
   aDir( 'OBJ\*.RES', aRESFiles )
   aDir( '*.MAP', aMAPFiles )
   aDir( '*.TDS', aTDSFiles )

   For i := 1 To Len( aOBJFilesB )
      DELETE FILE ( 'OBJ\' +  aOBJFilesB[i] )
   Next i
   For i := 1 To Len( aCFiles )
      DELETE FILE ( 'OBJ\' + aCFiles[i] )
   Next i
   For i := 1 To Len( aOFiles )
      DELETE FILE ( 'OBJ\' + aOFiles[i] )
   Next i
   For i := 1 To Len( aRESFiles )
      DELETE FILE ( 'OBJ\' + aRESFiles[i] )
   Next i
   For i := 1 To Len( aMAPFiles )
      DELETE FILE ( aMAPFiles[i] )
   Next i
   For i := 1 To Len( aTDSFiles )
      DELETE FILE ( aTDSFiles[i] )
   Next i

   DirRemove( 'OBJ' )

Return

Function refrefo()

local nrow:= form_1:row
local ncol:= form_1:col
local nwidth:= form_1:width
local nheight:= form_1:height
local clabel := "r:"+alltrim(str(nrow,4))+" c:"+alltrim(str(ncol,4))+" w:"+alltrim(str(nwidth,4))+" h:"+alltrim(str(nheight,4))
form_main:label_1:value :=  clabel
return nil

*------------------------------------------------------------------------------*
Function analizar( myIde, cFormx )
*------------------------------------------------------------------------------*
Local cItem,cParent
cItem:= Form_Tree:Tree_1:Item ( Form_Tree:Tree_1:value )
cParent= myIde:searchtype(citem)
if HB_IsString( cFormx )
   cParent:="Form module"
   cItem:=Cformx
endif
if cParent=='Form module' .and. cItem#cParent .and. cItem#'Project'
   if .not. myIde:form_activated
       form_main:frame_2:caption:="Control : "
       myIde:modifyform(cItem,cParent)
   else
       MsgStop( 'Can only edit one form at a time.', 'ooHG IDE+' )
       return nil
   endif
endif
if ( cParent=='Prg module' .and. cItem#cParent .and. cItem#'Project') .or. ;
   ( cParent=='CH module' .and. cItem#cParent )  .or. ;
   ( cParent=='RC module' .and. cItem#cParent )
   myIde:modifyitem(cItem,cParent)
endif
if cParent=='Rpt module' .and. cItem#cParent .and. cItem#'Project'
   myIde:modifyrpt(cItem,cParent)
endif
return nil

*------------------------------------------------------------------------------*
METHOD Exit() CLASS THMI
*------------------------------------------------------------------------------*
local a
if .not. ::lPsave
   If MsgYesNo( 'Project not saved, save it now?', 'ooHG IDE+' )
      ::saveproject()
   endif
endif
a:=MemoWrit( exedir, getcurrentfolder() )
if iswindowactive(Form_Tree)
   Form_Tree:release()
endif
Return

*-------------------------
METHOD printit() CLASS THMI
*-------------------------
LOCAL cItem, cParent, cArch

   SET INTERACTIVECLOSE ON
   PUBLIC _OOHG_PrintLibrary := "HBPRINTER"
   cItem := Form_Tree:Tree_1:Item( Form_Tree:Tree_1:value )
   cParent := ::searchtype( cItem )
   IF ::searchtype( cItem ) == 'Prg module' .AND. cItem # 'Prg module'
      cArch := MemoRead( cItem + '.prg' )
   ELSE
      IF ::searchtype( cItem ) == 'Form module' .AND. cItem # 'Form module'
         cArch := MemoRead( cItem + '.fmg' )
      ELSE
         IF ::searchtype( cItem ) == 'CH module' .AND. cItem # 'CH module'
            cArch := MemoRead( cItem + '.ch' )
         ELSE
            IF ::searchtype( cItem ) == 'Rpt module' .AND. cItem # 'Rpt module'
               cArch := MemoRead( cItem + '.rpt' )
            ELSE
               IF ::searchtype( cItem ) == 'RC module' .AND. cItem # 'RC module'
                  cArch := MemoRead( cItem + '.rc' )
               ELSE
                  MsgInfo( "This item can't be printed.", 'ooHG IDE+' )
                  RETURN NIL
               ENDIF
            ENDIF
         ENDIF
      ENDIF
   ENDIF
   ::ViewSource( cArch )
   SET INTERACTIVECLOSE OFF
RETURN NIL

/**********************************************/
Procedure CompileOptions( myIde, nOpt )
/**********************************************/

   Do Case
      Case nOpt = 1  // Only Make
           If ( myIde:nCompxBase=1 .and. myIde:nCompilerC=1 )  // Harbour-MinGW
              myIde:BldMinGW(0)
           Endif
           If ( myIde:nCompxBase=1 .and. myIde:nCompilerC=2 )  // Harbour-BCC
              myIde:BuildBcc(0)
           Endif
           If ( myIde:nCompxBase=1 .and. myIde:nCompilerC=3 )  // Harbour-PellesC
              myIde:BldPellc(0)
           Endif

           If ( myIde:nCompxBase=2 .and. myIde:nCompilerC=1 )  // xHarbour-MinGW
              myIde:xBldMinGW(0)
           Endif
           If ( myIde:nCompxBase=2 .and. myIde:nCompilerC=2 )  // xHarbour-BCC
              myIde:xBuildBcc(0)
           Endif
           If ( myIde:nCompxBase=2 .and. myIde:nCompilerC=3 )  // xHarbour-PellesC
              myIde:xBldPellc(0)
           Endif

      Case nOpt = 2  // Make and Run
           If ( myIde:nCompxBase=1 .and. myIde:nCompilerC=1 )  // Harbour-MinGW
              myIde:BldMinGW(1)
           Endif
           If ( myIde:nCompxBase=1 .and. myIde:nCompilerC=2 )  // Harbour-BCC
              myIde:BuildBcc(1)
           Endif
           If ( myIde:nCompxBase=1 .and. myIde:nCompilerC=3 )  // Harbour-PellesC
              myIde:BldPellc(1)
           Endif

           If ( myIde:nCompxBase=2 .and. myIde:nCompilerC=1 )  // xHarbour-MinGW
              myIde:xBldMinGW(1)
           Endif
           If ( myIde:nCompxBase=2 .and. myIde:nCompilerC=2 )  // xHarbour-BCC
              myIde:xBuildBcc(1)
           Endif
           If ( myIde:nCompxBase=2 .and. myIde:nCompilerC=3 )  // xHarbour-PellesC
              myIde:xBldPellc(1)
           Endif

      Case nOpt = 3  // Only Run
           myIde:runp()

      Case nOpt = 4  // Debug
           If ( myIde:nCompxBase=1 .and. myIde:nCompilerC=1 )  // Harbour-MinGW
              myIde:BldMinGW(2)
           Endif
           If ( myIde:nCompxBase=1 .and. myIde:nCompilerC=2 )  // Harbour-BCC
              myIde:BuildBcc(2)
           Endif
           If ( myIde:nCompxBase=1 .and. myIde:nCompilerC=3 )  // Harbour-PellesC
              myIde:BldPellc(2)
           Endif

           If ( myIde:nCompxBase=2 .and. myIde:nCompilerC=1 )  // xHarbour-MinGW
              myIde:xBldMinGW(2)
           Endif
           If ( myIde:nCompxBase=2 .and. myIde:nCompilerC=2 )  // xHarbour-BCC
              myIde:xBuildBcc(2)
           Endif
           If ( myIde:nCompxBase=2 .and. myIde:nCompilerC=3 )  // xHarbour-PellesC
              myIde:xBldPellc(2)
           Endif

   Endcase
Return

*-------------------------
Function printitem(carch)
*-------------------------
local oprint
IF !HB_IsString ( carch )
   Return nil
ENDIF
oprint:=tprint()
oprint:init()
oprint:selprinter(.T. , .T.  )  /// select,preview,land
if oprint:lprerror
   MsgStop( 'Error detected while printing.', 'ooHG IDE+' )
   oprint:release()
   return nil
endif
oprint:begindoc()
oprint:setpreviewsize(1)  /// tama�o del preview
oprint:beginpage()
oprint:setcpl(120)

contlin:=1
oprint:printdata(contlin,0, replicate('-',90))
wpage:=1
 for i:=1 to mlcount(carch)
    contlin++
    oprint:printdata(contlin,0,trim(MEMOLINE(CARCH,500,I) ) )
    IF contlin>60
       contlin++
       contlin++
       oprint:printdata(contlin,0,'Page... '+str(wpage,3) )
       contlin++
       oprint:printdata(contlin,0, replicate('-',90))
       oprint:endpage()
       oprint:beginpage()
       contlin:=1
       wpage++
    ENDIF
next i
 contlin++
contlin++
 oprint:printdata(contlin,0,'Page... '+str(wpage,3) )
contlin++
oprint:printdata(contlin,0, replicate('-',90))
contlin++
oprint:printdata(contlin,0,'End print ' )
oprint:endpage()
oprint:enddoc()
return nil

*-------------------------
METHOD about() CLASS THMI
*-------------------------
DEFINE WINDOW about_form obj about_form ;
   AT 0,0 ;
   WIDTH 450 ;
   HEIGHT 220 ;
   TITLE 'About ooHG IDE+ '  ;
   ICON 'Edit' ;
   MODAL NOSIZE NOSYSMENU ;
   backcolor ::asystemcolor

   @ 1,1    FRAME FRAME1 WIDTH 437 HEIGHT 190

   @ 15,330 Image Myphoto PICTURE 'cvcbmp' width 97 height 69     // MigSoft

   @ 85,330 Image MYOOHG  PICTURE 'myoohg' WIDTH 97 HEIGHT 97     // MigSoft

   @ 20,20  LABEL LB_NORM VALUE cNameApp ;
   FONT "Times new Roman"  SIZE 10  ;
   AUTOSIZE

   @ 40,20 HYPERLINK LB_MAIL ;
   VALUE "(c) 2002-2012 Ciro Vargas Clemow" ;
   ADDRESS 'pcman2010@yahoo.com' ;
   WIDTH 120 ;
   HEIGHT 24 ;
   AUTOSIZE ;
   FONT "Times new Roman" SIZE 10  ;
   TOOLTIP 'Click to email-me' HANDCURSOR ;

   @ 60,20  LABEL LB_NORM1 VALUE 'Original idea Roberto Lopez. (MiniGUI creator)' ;
   FONT "Times new Roman" SIZE 10  ;
   AUTOSIZE

   @ 80,20  LABEL LB_NORM2 VALUE 'Version '+miniguiversion() ;
   FONT "Times new Roman" SIZE 10  ;
   AUTOSIZE

   @ 100,20  LABEL LB_NORMooHG VALUE 'ooHG Creator  Vicente Guerra' ;
   FONT "Times new Roman" SIZE 10  ;
   AUTOSIZE

   @ 120,20 HYPERLINK LB_HOMEPAGE ;
   VALUE "(c) 2002-2014 ooHG IDE+ Home page" ;
   ADDRESS 'http://sistemascvc.tripod.com' ;
   WIDTH 120 ;
   HEIGHT 24 ;
   AUTOSIZE ;
   FONT "Times new Roman" SIZE 10  ;
   TOOLTIP 'Click to go'  ;
   HANDCURSOR

   @ 140,20  LABEL LB_NORM3 VALUE 'Dedicated to my dear sons, Ciro Andres , Santiago and Esteban.' ;
   FONT "Times new Roman" SIZE 9  ;
   AUTOSIZE

   @ 160,150 button button_1 caption 'Ok' action {|| about_form:release } FLAT


END WINDOW
about_form:button_1:setfocus()
center window about_form
playhand()
activate window about_form
return


*-------------------------
METHOD DataMan() CLASS THMI
*-------------------------
   If ! IsWindowDefined( _dbu )
      DatabaseView1( Self )
   Else
      MsgInfo( 'Data manager is already running.', 'ooHG IDE+' )
   EndIf
   Form_Tree:Maximize()
Return Nil


*-------------------------
METHOD SplashDelay() CLASS THMI
*-------------------------
local iTime
cursorwait()
iTime := Seconds()
Do While Seconds() - iTime < 1
EndDo
Form_Splash:release()
Form_Tree:maximize()
cursorarrow()
Return

*-------------------------
METHOD preferences() CLASS THMI
*-------------------------
   load window form_prefer

   form_prefer                    := getformobject("form_prefer")

   form_prefer:backcolor          := ::asystemcolor

   form_prefer:text_3:value       := ::cProjFolder
   form_prefer:text_4:value       := ::cOutFile

   form_prefer:text_12:value      := ::cGuiHbMinGW
   form_prefer:text_9:value       := ::cGuiHbBCC
   form_prefer:text_11:value      := ::cGuiHbPelles

   form_prefer:text_16:value      := ::cGuixHbMinGW
   form_prefer:text_17:value      := ::cGuixHbBCC
   form_prefer:text_18:value      := ::cGuixHbPelles

   form_prefer:text_8:value       := ::cHbMinGWFolder
   form_prefer:text_2:value       := ::cHbBCCFolder
   form_prefer:text_7:value       := ::cHbPellFolder

   form_prefer:text_13:value      := ::cxHbMinGWFolder
   form_prefer:text_14:value      := ::cxHbBCCFolder
   form_prefer:text_15:value      := ::cxHbPellFolder

   form_prefer:text_10:value      := ::cMinGWFolder
   form_prefer:text_5:value       := ::cBCCFolder
   form_prefer:text_6:value       := ::cPellFolder

   form_prefer:radiogroup_1:value := ::nCompxBase
   form_prefer:radiogroup_2:value := ::nCompilerC

   form_prefer:text_1:value       := ::cExteditor

   form_prefer:Radiogroup_3:value := ::ltbuild
   form_prefer:text_lib:value     := ::clib
   form_prefer:checkbox_105:value := iif(::lsnap=1,.T.,.F.)

   form_prefer:checkbox_105:backcolor := ::asystemcolor
   form_prefer:button_101:backcolor   := ::asystemcolor
   form_prefer:button_102:backcolor   := ::asystemcolor

   ACTIVATE WINDOW form_prefer

return


*-------------------------
METHOD searchtext() CLASS THMI
*-------------------------
local cTextsearch,i,nItems,cInput,cOutput,cItem,j
cTextsearch:=inputbox('Text','Search text')
if len(cTextsearch)=0
   return nil
endif
cursorwait()
waitmess:hmi_label_101:value:='Searching....'
waitmess:show()
nItems:=Form_Tree:Tree_1:ItemCount
cOutput:=''
For i:= 1  to nItems

    cItem:=Form_Tree:Tree_1:Item (i)

    if ::searchtypeadd(i)=='RC module' .and. cItem<>'RC module'
       if file(cItem+'.rc')
          cInput:=memoread(cItem+'.rc')
          for j:=1 to mlcount(cInput)
              if at(upper(ctextsearch),upper(trim(memoline(cInput,500,j))))>0
                 cOutput += cItem+'  ==> RC module'+'  Line '+str(j,6)+CRLF
              endif
          next j
       endif
    else
    if ::searchtypeadd(i)=='CH module' .and. cItem<>'CH module'
       if file(cItem+'.ch')
          cInput:=memoread(cItem+'.ch')
          for j:=1 to mlcount(cInput)
              if at(upper(ctextsearch),upper(trim(memoline(cInput,500,j))))>0
                 cOutput += cItem+'  ==> CH module'+'  Line '+str(j,6)+CRLF
              endif
          next j
       endif
    else
    if (::searchtypeadd(i)=='Prg module') .and.( cItem<>'Prg module')
       if file(citem+'.prg')
          cInput:=memoread(cItem+'.prg')
          for j:=1 to mlcount(cInput)
              if at(upper(ctextsearch),upper(trim(memoline(cInput,500,j))))>0
                 coutput += cItem+'  ==> Prg module '+'  Line '+str(j,6)+CRLF
              endif
          next j
       endif
    else
    if (::searchtypeadd(i)=='Form module') .and.( cItem<>'Form module')
       if file(citem+'.fmg')
          cInput:=memoread(cItem+'.fmg')
          for j:=1 to mlcount(cInput)
              if at(upper(ctextsearch),upper(trim(memoline(cInput,500,j))))>0
                 coutput += cItem+'  ==> Form module'+'  Line '+str(j,6)+CRLF
              endif
          next j
       endif
    else
    if (::searchtypeadd(i)=='Rpt module') .and.( cItem<>'Rpt module')
       if file(citem+'.rpt')
          cInput:=memoread(cItem+'.rpt')
          for j:=1 to mlcount(cInput)
              if at(upper(ctextsearch),upper(trim(memoline(cInput,500,j))))>0
                 coutput += cItem+'  ==> Rpt module'+'  Line '+str(j,6)+CRLF
              endif
          next j
       endif
    endif
    endif
    endif
    endif
    endif
Next i
waitmess:hide()
cursorarrow()
if coutput==''
   MsgInfo( 'Text not found.', 'ooHG IDE+' )
else
   MsgInfo( cTextsearch + ' found in: ' + CRLF + coutput, 'ooHG IDE+' )
endif
return

*-------------------------
METHOD okprefer() CLASS THMI
*-------------------------

   ::cProjFolder     := pmgFolder                     // MigSoft
   ::cOutFile        := form_prefer:text_4:value

   if len(trim(form_prefer:text_1:value))=0
      ::cExteditor:=""
   else
      ::cExteditor:=form_prefer:text_1:value
   endif

   ::cGuiHbMinGW     := form_prefer:text_12:value
   ::cGuiHbBCC       := form_prefer:text_9:value
   ::cGuiHbPelles    := form_prefer:text_11:value
   ::cGuixHbMinGW    := form_prefer:text_16:value
   ::cGuixHbBCC      := form_prefer:text_17:value
   ::cGuixHbPelles   := form_prefer:text_18:value

   ::cHbMinGWFolder  := form_prefer:text_8:value
   ::cHbBCCFolder    := form_prefer:text_2:value
   ::cHbPellFolder   := form_prefer:text_7:value

   ::cxHbMinGWFolder :=  form_prefer:text_13:value
   ::cxHbBCCFolder   :=  form_prefer:text_14:value
   ::cxHbPellFolder  :=  form_prefer:text_15:value

   ::cMinGWFolder    := form_prefer:text_10:value
   ::cBCCFolder      := form_prefer:text_5:value
   ::cPellFolder     := form_prefer:text_6:value

   ::nCompxBase      := form_prefer:radiogroup_1:value
   ::nCompilerC      := form_prefer:radiogroup_2:value

   ::ltbuild         := form_prefer:Radiogroup_3:value
   ::lsnap           := iif(form_prefer:checkbox_105:value,1,0)
   ::clib            := form_prefer:text_lib:value

   form_prefer:release()

   SetCurrentFolder(::cProjFolder)    // MigSoft

   BEGIN INI FILE 'hmi.INI'

         SET SECTION 'PROJECT'  ENTRY "PROJFOLDER"   TO ::cProjFolder
         SET SECTION 'PROJECT'  ENTRY "OUTFILE"      TO ::cOutFile

         SET SECTION "EDITOR"   ENTRY "EXTERNAL"     TO ::cExteditor

         SET SECTION 'GUILIB'   ENTRY "GUIHBMINGW"   TO ::cGuiHbMinGW
         SET SECTION 'GUILIB'   ENTRY "GUIHBBCC"     TO ::cGuiHbBCC
         SET SECTION 'GUILIB'   ENTRY "GUIHBPELL"    TO ::cGuiHBPelles
         SET SECTION 'GUILIB'   ENTRY "GUIXHBMINGW"  TO ::cGuixHbMinGW
         SET SECTION 'GUILIB'   ENTRY "GUIXHBBCC"    TO ::cGuixHbBCC
         SET SECTION 'GUILIB'   ENTRY "GUIXHBPELL"   TO ::cGuixHBPelles

         SET SECTION 'HARBOUR'  ENTRY "HBMINGW"      TO ::cHbMinGWFolder
         SET SECTION 'HARBOUR'  ENTRY "HBBCC"        TO ::cHbBCCFolder
         SET SECTION 'HARBOUR'  ENTRY "HBPELLES"     TO ::cHbPellFolder

         SET SECTION 'HARBOUR'  ENTRY "XHBMINGW"     TO ::cxHbMinGWFolder
         SET SECTION 'HARBOUR'  ENTRY "XHBBCC"       TO ::cxHbBCCFolder
         SET SECTION 'HARBOUR'  ENTRY "XHBPELLES"    TO ::cxHbPellFolder

         SET SECTION 'COMPILER' ENTRY "MINGWFOLDER"  TO ::cMinGWFolder
         SET SECTION 'COMPILER' ENTRY "BCCFOLDER"    TO ::cBCCFolder
         SET SECTION 'COMPILER' ENTRY "PELLESFOLDER" TO ::cPellFolder

         SET SECTION 'WHATCOMP' ENTRY "XBASECOMP"    TO ::nCompxBase
         SET SECTION 'WHATCOMP' ENTRY "CCOMPILER"    TO ::nCompilerC

         SET SECTION "SETTINGS" ENTRY "BUILD"        to ::ltbuild
         SET SECTION "SETTINGS" ENTRY "LIB"          to ::clib
         SET SECTION "SETTINGS" ENTRY "SNAP"         to ::lsnap

   END INI

Return

*-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._-._.-._.-._.-._.-._.-._.-._
*                     COMPILING WITH MINGW AND HARBOUR
*-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._-._.-._.-._.-._.-._.-._.-._

//------------------------------------------------------------------------------
METHOD BldMinGW( nOption ) CLASS THMI
//------------------------------------------------------------------------------
   Local aPrgFiles
   Local aRcFiles
   Local cCompFolder := ::cMinGWFolder + '\'
   Local cDosComm
   Local cError
   Local cError1
   Local cExe
   Local cFile
   Local cHarbourFolder := ::cHbMinGWFolder + '\'
   Local cMiniGuiFolder := ::cGUIHbMinGW + '\'
   Local cOut
   Local cPrgName
   Local cProjFolder := ::cProjFolder + '\'
   Local i
   Local nItems
   Local nPrgFiles

   Form_Tree:button_9:Enabled := .F.
   Form_Tree:button_10:Enabled := .F.
   Form_Tree:button_11:Enabled := .F.
   CursorWait()
   waitmess:hmi_label_101:Value := 'Compiling ...'
   waitmess:Show()

   Begin Sequence
      // Check folders
      If Empty( ::cProjectName )
         waitmess:Hide()
         MsgStop( 'You must save the project before building it.', 'ooHG IDE+' )
         Break
      EndIf

      If Empty( cCompFolder )
         waitmess:Hide()
         MsgStop( 'The MinGW folder must be specified to build a project.', 'ooHG IDE+' )
         Break
      EndIf

      If Empty( cMiniGuiFolder )
         waitmess:Hide()
         MsgStop( 'The ooHG-Hb-MinGW folder must be specified to build a project.', 'ooHG IDE+' )
         Break
      EndIf

      If Empty( cHarbourFolder )
         waitmess:Hide()
         MsgStop( 'The Harbour-MinGW folder must be specified to build a project.', 'ooHG IDE+' )
         Break
      EndIf

      // Prepare to build
      SetCurrentFolder( cProjFolder )
      BorraTemp( cProjFolder )
      cPrgName := StrTran( AllTrim( DelExt( DelPath( ::cProjectName ) ) ), " ", "_" )
      cExe := cPrgName + '.exe'
      If File( cExe )
         DELETE FILE ( cExe )
      EndIf
      If File( cExe )
         waitmess:Hide()
         MsgInfo( 'Error building project.' + CRLF + 'Is EXE running?', 'ooHG IDE+' )
         Break
      EndIf

      Do Case
      Case ::lTBuild == 2    // Own Make

         // Build list of source files
         nItems := Form_Tree:Tree_1:ItemCount
         aPrgFiles := {}
         aRcFiles := {}
         For i := 1 To nItems
            cFile := Form_Tree:Tree_1:Item( i )
            If ::SearchTypeAdd( ::SearchItem( cFile, 'Prg module' ) ) == 'Prg module' .and. cFile <> 'Prg module'
               cFile := Upper( AllTrim( cFile ) )
               If aScan( aPrgFiles, cFile ) == 0
                  aAdd( aPrgFiles, cFile )
               EndIf
            ElseIf ::SearchTypeAdd( ::SearchItem( cFile, 'RC module' ) ) == 'RC module' .and. cFile <> 'RC module'
               cFile := Upper( AllTrim( cFile ) )
               If aScan( aRcFiles, cFile ) == 0
                  aAdd( aRcFiles, cFile )
               EndIf
            EndIf
         Next i
         nPrgFiles := Len( aPrgFiles )
         If nPrgFiles == 0
            waitmess:Hide()
            MsgStop( 'Project has no .PRG files.', 'ooHG IDE+' )
            Break
         EndIf

         // Build make script
         // Variables
         cOut := ''
         cOut += 'PATH          = ' + cCompFolder + 'BIN' + CRLF
         cOut += 'PROJECTFOLDER = ' + DelSlash( cProjFolder ) + CRLF
         cOut += 'APP_NAME      = ' + cExe + CRLF
         cOut += 'OBJ_DIR       = ' + cProjFolder + 'OBJ' + CRLF
         cOut += 'OBJECTS       = '
         For i := 1 To nPrgFiles
            cOut += '\' + CRLF + '$(OBJ_DIR)\' + aPrgFiles[i] + '.o '
         Next i
         For i := 1 to Len( aRcFiles )
            cOut += '\' + CRLF + '$(OBJ_DIR)\_temp.o'
         Next i
         cOut += CRLF
         cOut += 'LINK_EXE      = GCC.EXE' + CRLF
         cOut += 'LINK_FLAGS    = -Wall -mwindows -O3 -Wl,--allow-multiple-definition' + CRLF
         cOut += 'LINK_SEARCH   = -L' + DelSlash( cProjFolder ) + ;
                                ' -L' + cCompFolder + 'LIB' + ;
                                ' -L' + cHarbourFolder + If( File( cHarbourFolder + 'LIB\WIN\MINGW\LIBHBRTL.A' ), 'LIB\WIN\MINGW', 'LIB' ) + ;
                                ' -L' + cMiniGUIFolder + If( File( cMiniGUIFolder + 'LIB\HB\MINGW\LIBOOHG.A' ), 'LIB\HB\MINGW', 'LIB' ) + CRLF
         cOut += 'LINK_LIBS     = -Wl,--start-group -looHG -lhbprinter -lminiprint -lgtgui ' + ;
                                  '-lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbziparc ' + ;
                                  '-lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc ' + ;
                                  '-lodbc32 -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 ' + ;
                                  '-lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 ' + ;
                                  If( nOption == 2, '-lgtwin ', '' ) + ;
                                  '-Wl,--end-group' + CRLF
         cOut += 'CC_EXE        = GCC.EXE' + CRLF
         cOut += 'CC_FLAGS      = -Wall -mwindows -O3' + CRLF
         cOut += 'CC_SEARCH     = -I' + DelSlash( cProjFolder ) + ;
                                ' -I' + cCompFolder + 'INCLUDE' + ;
                                ' -I' + cHarbourFolder + 'INCLUDE' + ;
                                ' -I' + cMiniGUIFolder + 'INCLUDE' + CRLF
         cOut += 'HRB_EXE       = ' + cHarbourFolder + 'BIN\HARBOUR.EXE' + CRLF
         cOut += 'HRB_FLAGS     = -n -q ' + If( nOption == 2, "-b ", "" ) + CRLF
         cOut += 'HRB_SEARCH    = -i' + DelSlash( cProjFolder ) + ;
                                ' -i' + cHarbourFolder + 'INCLUDE' + ;
                                ' -i' + cMiniGUIFolder + 'INCLUDE' + CRLF
         cOut += 'RC_COMP       = WINDRES.EXE' + CRLF
         cOut += CRLF
         // Rule for .exe building
         cOut += '$(APP_NAME) : $(OBJECTS)' + CRLF
         cOut += HTAB + '$(LINK_EXE) $(LINK_FLAGS) -o$(APP_NAME) $^ $(LINK_SEARCH) $(LINK_LIBS)' + CRLF
         cOut += CRLF
         // Rule for .c compiling
         For i := 1 To nPrgFiles
            cOut += '$(OBJ_DIR)\' + aPrgFiles[i] + '.o : $(OBJ_DIR)\' + aPrgFiles[i] + '.c' + CRLF
            cOut += HTAB + '$(CC_EXE) $(CC_FLAGS) $(CC_SEARCH) -c $^ -o $@' + CRLF
            cOut += HTAB + '@echo #' + CRLF
         cOut += CRLF
         Next i
         cOut += CRLF
         // Rule for .prg compiling
         For i := 1 To nPrgFiles
            cOut += '$(OBJ_DIR)\' + aPrgFiles[i] + '.c : $(PROJECTFOLDER)\' + aPrgFiles[i] + '.prg' + CRLF
            cOut += HTAB + '$(HRB_EXE) $^ $(HRB_FLAGS) $(HRB_SEARCH) -o$@' + CRLF
            cOut += HTAB + '@echo #' + CRLF
         Next i
         cOut += CRLF
         // Rule for .rc compiling
         cOut += '$(OBJ_DIR)\_temp.o : $(PROJECTFOLDER)\_temp.rc' + CRLF
         cOut += HTAB + '$(RC_COMP) -i $^ -o $@' + CRLF
         cOut += HTAB + '@echo #' + CRLF
         MemoWrit( 'Makefile.Gcc', cOut )

         // Build batch to create RC temp file
         cOut := ''
         cOut += '@echo off' + CRLF
         cOut += 'echo #define oohgpath ' + cMiniGUIFolder + 'resources > ' + cProjFolder + '_oohg_resconfig.h' + CRLF
         cOut += 'copy /b ' + cMiniGUIFolder + 'resources\oohg.rc _temp.rc > NUL' + CRLF
         For i := 1 To Len( aRcFiles )
            If File( aRcFiles[ i ] )
               cOut += 'copy /b _temp.rc _aux.rc > NUL' + CRLF
               cOut += 'copy /b _aux.rc + ' + aRcFiles[ i ] + ' _temp.rc > NUL' + CRLF
            EndIf
         Next i

         // Build batch to launch make utility
         cOut += cCompFolder + 'BIN\mingw32-make.exe -f makefile.gcc 1>error.lst 2>&1 3>&2' + CRLF
         MemoWrit( '_build.bat', cOut )

         // Create temp folder for objects
         CreateFolder( cProjFolder + 'OBJ' )

         // Compile and link
         EXECUTE FILE '_build.bat' WAIT HIDE

      Case ::lTBuild == 1 // Compile.bat

         // Check for compile file
         If ! File( 'compile.bat' ) .and. ! IsFileInPath( 'compile.bat' )
            waitmess:Hide()
            MsgInfo( 'Copy file COMPILE.BAT from ooHG root folder to the current' + CRLF + 'project folder, or add ooHG root folder to PATH.', 'ooHG IDE+' )
            Break
         EndIf

         // Build auxiliary source file
         nItems := Form_Tree:Tree_1:ItemCount
         aPrgFiles := {}
         For i := 1 To nItems
            cFile := Form_Tree:Tree_1:Item( i )
            If ::SearchTypeAdd( ::SearchItem( cFile, 'Prg module' ) ) == 'Prg module' .and. cFile <> 'Prg module'
               cFile := Upper( AllTrim( cFile + '.PRG' ) )
               If aScan( aPrgFiles, cFile ) == 0
                  aAdd( aPrgFiles, cFile )
               EndIf
            EndIf
         Next i
         nPrgFiles := Len( aPrgFiles )
         If nPrgFiles == 0
            waitmess:Hide()
            MsgStop( 'Project has no .PRG files.', 'ooHG IDE+' )
            Break
         EndIf
         cOut := ''
         For i := 1 To nPrgFiles
            cOut += "# include '" + aPrgFiles[i] + "'" + CRLF + CRLF
         Next i
         MemoWrit( cPrgName + '.prg', cOut )

         // Compile and link
         cDosComm := '/c compile ' + cPrgName + ' /nr /l' + If( nOption == 2, " /d", "" )
         EXECUTE FILE 'CMD.EXE' PARAMETERS cDosComm HIDE

      EndCase

      // Check for errors
      cError := MemoRead( 'error.lst' )
      cError1 := Upper( cError )
      If At( 'ERROR', cError1 ) > 0 .or. At( 'FATAL', cError1 ) > 0 .or. At( 'LD RETURNED 1 EXIT STATUS', cError1 ) > 0
         waitmess:Hide()
         ::ViewErrors( cError )
         Break
      ElseIf ! File( cExe )
         waitmess:Hide()
         MsgStop( 'EXE is missing.', 'ooHG IDE+' )
         Break
      EndIf

      // Rename or move
      If ! Empty( ::cOutFile )
         cOut := Upper( AllTrim( ::cOutFile ) )
         If Right( cOut, 4 ) != ".EXE"
            cOut += ".EXE"
         EndIf
         cDosComm := '/c move ' + cExe + ' ' + cOut
         EXECUTE FILE 'CMD.EXE' PARAMETERS cDosComm HIDE
         If ! File( cOut )
            waitmess:Hide()
            MsgStop( "Can't move or rename EXE file.", 'ooHG IDE+' )
            Break
         EndIf
         cExe := cOut
      EndIf

      // Cleanup
      BorraTemp( cProjFolder )
      waitmess:Hide()
      If nOption == 0
         MsgInfo( 'Project builded.', 'ooHG IDE+' )
      ElseIf nOption == 1 .or. nOption == 2
         EXECUTE FILE cExe
      EndIf
   End Sequence

   CursorArrow()
   Form_Tree:button_9:Enabled := .T.
   Form_Tree:button_10:Enabled := .T.
   Form_Tree:button_11:Enabled := .T.
Return

//------------------------------------------------------------------------------
METHOD RunP() CLASS THMI
//------------------------------------------------------------------------------
   Local cExe

   Form_Tree:button_9:Enabled := .F.
   Form_Tree:button_10:Enabled := .F.
   Form_Tree:button_11:Enabled := .F.

   cExe := StrTran( AllTrim( DelExt( ::cProjectName ) ), " ", "_" ) + '.exe'
   If File( cExe )
      EXECUTE FILE cExe
   else
      MsgStop( 'EXE is missing.', 'ooHG IDE+' )
   endif

   Form_Tree:button_9:Enabled := .T.
   Form_Tree:button_10:Enabled := .T.
   Form_Tree:button_11:Enabled := .T.
Return Nil

*-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._-._.-._.-._.-._.-._.-._.-._
*                   COMPILING WITH MINGW AND XHARBOUR
*-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._-._.-._.-._.-._.-._.-._.-._

//------------------------------------------------------------------------------
METHOD xBldMinGW( nOption ) CLASS THMI
//------------------------------------------------------------------------------
   Local aPrgFiles
   Local aRcFiles
   Local cCompFolder := ::cMinGWFolder + '\'
   Local cDosComm
   Local cError
   Local cError1
   Local cExe
   Local cFile
   Local cHarbourFolder := ::cxHbMinGWFolder + '\'
   Local cMiniGuiFolder := ::cGUIxHbMinGW + '\'
   Local cOut
   Local cPrgName
   Local cProjFolder := ::cProjFolder + '\'
   Local i
   Local nItems
   Local nPrgFiles

   Form_Tree:button_9:Enabled := .F.
   Form_Tree:button_10:Enabled := .F.
   Form_Tree:button_11:Enabled := .F.
   CursorWait()
   waitmess:hmi_label_101:Value := 'Compiling ...'
   waitmess:Show()

   Begin Sequence
      // Check folders
      If Empty( ::cProjectName )
         waitmess:Hide()
         MsgStop( 'You must save the project before building it.', 'ooHG IDE+' )
         Break
      EndIf

      If Empty( cCompFolder )
         waitmess:Hide()
         MsgStop( 'The MinGW folder must be specified to build a project.', 'ooHG IDE+' )
         Break
      EndIf

      If Empty( cMiniGuiFolder )
         waitmess:Hide()
         MsgStop( 'The ooHG-xHb-MinGW folder must be specified to build a project.', 'ooHG IDE+' )
         Break
      EndIf

      If Empty( cHarbourFolder )
         waitmess:Hide()
         MsgStop( 'The xHarbour-MinGW folder must be specified to build a project.', 'ooHG IDE+' )
         Break
      EndIf

      // Prepare to build
      SetCurrentFolder( cProjFolder )
      BorraTemp( cProjFolder )
      cPrgName := StrTran( AllTrim( DelExt( DelPath( ::cProjectName ) ) ), " ", "_" )
      cExe := cPrgName + '.exe'
      If File( cExe )
         DELETE FILE ( cExe )
      EndIf
      If File( cExe )
         waitmess:Hide()
         MsgInfo( 'Error building project.' + CRLF + 'Is EXE running?', 'ooHG IDE+' )
         Break
      EndIf

      Do Case
      Case ::lTBuild == 2    // Own Make

         // Build list of source files
         nItems := Form_Tree:Tree_1:ItemCount
         aPrgFiles := {}
         aRcFiles := {}
         For i := 1 To nItems
            cFile := Form_Tree:Tree_1:Item( i )
            If ::SearchTypeAdd( ::SearchItem( cFile, 'Prg module' ) ) == 'Prg module' .and. cFile <> 'Prg module'
               cFile := Upper( AllTrim( cFile ) )
               If aScan( aPrgFiles, cFile ) == 0
                  aAdd( aPrgFiles, cFile )
               EndIf
            ElseIf ::SearchTypeAdd( ::SearchItem( cFile, 'RC module' ) ) == 'RC module' .and. cFile <> 'RC module'
               cFile := Upper( AllTrim( cFile ) )
               If aScan( aRcFiles, cFile ) == 0
                  aAdd( aRcFiles, cFile )
               EndIf
            EndIf
         Next i
         nPrgFiles := Len( aPrgFiles )
         If nPrgFiles == 0
            waitmess:Hide()
            MsgStop( 'Project has no .PRG files.', 'ooHG IDE+' )
            Break
         EndIf

         // Build make script
         // Variables
         cOut := ''
         cOut += 'PATH          = ' + cCompFolder + 'BIN' + CRLF
         cOut += 'PROJECTFOLDER = ' + DelSlash( cProjFolder ) + CRLF
         cOut += 'APP_NAME      = ' + cExe + CRLF
         cOut += 'OBJ_DIR       = ' + cProjFolder + 'OBJ' + CRLF
         cOut += 'OBJECTS       = '
         For i := 1 To nPrgFiles
            cOut += '\' + CRLF + '$(OBJ_DIR)\' + aPrgFiles[i] + '.o '
         Next i
         For i := 1 to Len( aRcFiles )
            cOut += '\' + CRLF + '$(OBJ_DIR)\_temp.o'
         Next i
         cOut += CRLF
         cOut += 'LINK_EXE      = GCC.EXE' + CRLF
         cOut += 'LINK_FLAGS    = -Wall -mwindows -O3 -Wl,--allow-multiple-definition' + CRLF
         cOut += 'LINK_SEARCH   = -L' + DelSlash( cProjFolder ) + ;
                                ' -L' + cCompFolder + 'LIB' + ;
                                ' -L' + cHarbourFolder + If( File( cHarbourFolder + 'LIB\WIN\MINGW\LIBHBRTL.A' ), 'LIB\WIN\MINGW', 'LIB' ) + ;
                                ' -L' + cMiniGUIFolder + If( File( cMiniGUIFolder + 'LIB\XHB\MINGW\LIBOOHG.A' ), 'LIB\XHB\MINGW', 'LIB' ) + CRLF
         cOut += 'LINK_LIBS     = -Wl,--start-group -looHG -lhbprinter -lminiprint -lgtgui ' + ;
                                  '-lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbziparc ' + ;
                                  '-lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc ' + ;
                                  '-lodbc32 -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 ' + ;
                                  '-lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 ' + ;
                                  If( nOption == 2, '-lgtwin ', '' ) + ;
                                  '-Wl,--end-group' + CRLF
         cOut += 'CC_EXE        = GCC.EXE' + CRLF
         cOut += 'CC_FLAGS      = -Wall -mwindows -O3' + CRLF
         cOut += 'CC_SEARCH     = -I' + DelSlash( cProjFolder ) + ;
                                ' -I' + cCompFolder + 'INCLUDE' + ;
                                ' -I' + cHarbourFolder + 'INCLUDE' + ;
                                ' -I' + cMiniGUIFolder + 'INCLUDE' + CRLF
         cOut += 'HRB_EXE       = ' + cHarbourFolder + 'BIN\HARBOUR.EXE' + CRLF
         cOut += 'HRB_FLAGS     = -n -q ' + If( nOption == 2, "-b ", "" ) + CRLF
         cOut += 'HRB_SEARCH    = -i' + DelSlash( cProjFolder ) + ;
                                ' -i' + cHarbourFolder + 'INCLUDE' + ;
                                ' -i' + cMiniGUIFolder + 'INCLUDE' + CRLF
         cOut += 'RC_COMP       = WINDRES.EXE' + CRLF
         cOut += CRLF
         // Rule for .exe building
         cOut += '$(APP_NAME) : $(OBJECTS)' + CRLF
         cOut += HTAB + '$(LINK_EXE) $(LINK_FLAGS) -o$(APP_NAME) $^ $(LINK_SEARCH) $(LINK_LIBS)' + CRLF
         cOut += CRLF
         // Rule for .c compiling
         For i := 1 To nPrgFiles
            cOut += '$(OBJ_DIR)\' + aPrgFiles[i] + '.o : $(OBJ_DIR)\' + aPrgFiles[i] + '.c' + CRLF
            cOut += HTAB + '$(CC_EXE) $(CC_FLAGS) $(CC_SEARCH) -c $^ -o $@' + CRLF
            cOut += HTAB + '@echo #' + CRLF
         cOut += CRLF
         Next i
         cOut += CRLF
         // Rule for .prg compiling
         For i := 1 To nPrgFiles
            cOut += '$(OBJ_DIR)\' + aPrgFiles[i] + '.c : $(PROJECTFOLDER)\' + aPrgFiles[i] + '.prg' + CRLF
            cOut += HTAB + '$(HRB_EXE) $^ $(HRB_FLAGS) $(HRB_SEARCH) -o$@' + CRLF
            cOut += HTAB + '@echo #' + CRLF
         Next i
         cOut += CRLF
         // Rule for .rc compiling
         cOut += '$(OBJ_DIR)\_temp.o : $(PROJECTFOLDER)\_temp.rc' + CRLF
         cOut += HTAB + '$(RC_COMP) -i $^ -o $@' + CRLF
         cOut += HTAB + '@echo #' + CRLF
         MemoWrit( 'Makefile.Gcc', cOut )

         // Build batch to create RC temp file
         cOut := ''
         cOut += '@echo off' + CRLF
         cOut += 'echo #define oohgpath ' + cMiniGUIFolder + 'resources > ' + cProjFolder + '_oohg_resconfig.h' + CRLF
         cOut += 'copy /b ' + cMiniGUIFolder + 'resources\oohg.rc _temp.rc > NUL' + CRLF
         For i := 1 To Len( aRcFiles )
            If File( aRcFiles[ i ] )
               cOut += 'copy /b _temp.rc _aux.rc > NUL' + CRLF
               cOut += 'copy /b _aux.rc + ' + aRcFiles[ i ] + ' _temp.rc > NUL' + CRLF
            EndIf
         Next i

         // Build batch to launch make utility
         cOut += cCompFolder + 'BIN\mingw32-make.exe -f makefile.gcc 1>error.lst 2>&1 3>&2' + CRLF
         MemoWrit( '_build.bat', cOut )

         // Create temp folder for objects
         CreateFolder( cProjFolder + 'OBJ' )

         // Compile and link
         EXECUTE FILE '_build.bat' WAIT HIDE

      Case ::lTBuild == 1 // Compile.bat

         // Check for compile file
         If ! File( 'compile.bat' ) .and. ! IsFileInPath( 'compile.bat' )
            waitmess:Hide()
            MsgInfo( 'Copy file COMPILE.BAT from ooHG root folder to the current' + CRLF + 'project folder, or add ooHG root folder to PATH.', 'ooHG IDE+' )
            Break
         EndIf

         // Build auxiliary source file
         nItems := Form_Tree:Tree_1:ItemCount
         aPrgFiles := {}
         For i := 1 To nItems
            cFile := Form_Tree:Tree_1:Item( i )
            If ::SearchTypeAdd( ::SearchItem( cFile, 'Prg module' ) ) == 'Prg module' .and. cFile <> 'Prg module'
               cFile := Upper( AllTrim( cFile + '.PRG' ) )
               If aScan( aPrgFiles, cFile ) == 0
                  aAdd( aPrgFiles, cFile )
               EndIf
            EndIf
         Next i
         nPrgFiles := Len( aPrgFiles )
         If nPrgFiles == 0
            waitmess:Hide()
            MsgStop( 'Project has no .PRG files.', 'ooHG IDE+' )
            Break
         EndIf
         cOut := ''
         For i := 1 To nPrgFiles
            cOut += "# include '" + aPrgFiles[i] + "'" + CRLF + CRLF
         Next i
         MemoWrit( cPrgName + '.prg', cOut )

         // Compile and link
         cDosComm := '/c compile ' + cPrgName + ' /nr /l' + If( nOption == 2, " /d", "" )
         EXECUTE FILE 'CMD.EXE' PARAMETERS cDosComm HIDE

      EndCase

      // Check for errors
      cError := MemoRead( 'error.lst' )
      cError1 := Upper( cError )
      If At( 'ERROR', cError1 ) > 0 .or. At( 'FATAL', cError1 ) > 0 .or. At( 'LD RETURNED 1 EXIT STATUS', cError1 ) > 0
         waitmess:Hide()
         ::ViewErrors( cError )
         Break
      ElseIf ! File( cExe )
         waitmess:Hide()
         MsgStop( 'EXE is missing.', 'ooHG IDE+' )
         Break
      EndIf

      // Rename or move
      If ! Empty( ::cOutFile )
         cOut := Upper( AllTrim( ::cOutFile ) )
         If Right( cOut, 4 ) != ".EXE"
            cOut += ".EXE"
         EndIf
         cDosComm := '/c move ' + cExe + ' ' + cOut
         EXECUTE FILE 'CMD.EXE' PARAMETERS cDosComm HIDE
         If ! File( cOut )
            waitmess:Hide()
            MsgStop( "Can't move or rename EXE file.", 'ooHG IDE+' )
            Break
         EndIf
         cExe := cOut
      EndIf

      // Cleanup
      BorraTemp( cProjFolder )
      waitmess:Hide()
      If nOption == 0
         MsgInfo( 'Project builded.', 'ooHG IDE+' )
      ElseIf nOption == 1 .or. nOption == 2
         EXECUTE FILE cExe
      EndIf
   End Sequence

   CursorArrow()
   Form_Tree:button_9:Enabled := .T.
   Form_Tree:button_10:Enabled := .T.
   Form_Tree:button_11:Enabled := .T.
Return

*-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._-._.-._.-._.-._.-._.-._.-._
*                 COMPILING WITH BORLAND C AND HARBOUR
*-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._-._.-._.-._.-._.-._.-._.-._

//------------------------------------------------------------------------------
METHOD BuildBCC( nOption ) CLASS THMI
//------------------------------------------------------------------------------
   Local aPrgFiles
   Local aRcFiles
   Local cCompFolder := ::cBCCFolder + '\'
   Local cDosComm
   Local cError
   Local cError1
   Local cExe
   Local cFile
   Local cHarbourFolder := ::cHbBCCFolder + '\'
   Local cMiniGuiFolder := ::cGuiHbBCC + '\'
   Local cOut
   Local cPrgName
   Local cProjFolder := ::cProjFolder + '\'
   Local i
   Local nItems
   Local nPrgFiles

   Form_Tree:button_9:Enabled := .F.
   Form_Tree:button_10:Enabled := .F.
   Form_Tree:button_11:Enabled := .F.
   CursorWait()
   waitmess:hmi_label_101:Value := 'Compiling ...'
   waitmess:Show()

   Begin Sequence
      // Check folders
      If Empty( ::cProjectName )
         waitmess:Hide()
         MsgStop( 'You must save the project before building it.', 'ooHG IDE+' )
         Break
      EndIf

      If Empty( cCompFolder )
         waitmess:Hide()
         MsgStop( 'The BCC folder must be specified to build a project.', 'ooHG IDE+' )
         Break
      EndIf

      If Empty( cMiniGuiFolder )
         waitmess:Hide()
         MsgStop( 'The ooHG-Hb-BCC folder must be specified to build a project.', 'ooHG IDE+' )
         Break
      EndIf

      If Empty( cHarbourFolder )
         waitmess:Hide()
         MsgStop( 'The Harbour-Borland C folder must be specified to build a project.', 'ooHG IDE+' )
         Break
      EndIf

      // Prepare to build
      SetCurrentFolder( cProjFolder )
      BorraTemp( cProjFolder )
      cPrgName := StrTran( AllTrim( DelExt( DelPath( ::cProjectName ) ) ), " ", "_" )
      cExe := cPrgName + '.exe'
      If File( cExe )
         DELETE FILE ( cExe )
      EndIf
      If File( cExe )
         waitmess:Hide()
         MsgInfo( 'Error building project.' + CRLF + 'Is EXE running?', 'ooHG IDE+' )
         Break
      EndIf

      Do Case
      Case ::lTBuild == 2    // Own Make

         // Build list of source files
         nItems := Form_Tree:Tree_1:ItemCount
         aPrgFiles := {}
         aRcFiles := {}
         For i := 1 To nItems
            cFile := Form_Tree:Tree_1:Item( i )
            If ::SearchTypeAdd( ::SearchItem( cFile, 'Prg module' ) ) == 'Prg module' .and. cFile <> 'Prg module'
               cFile := Upper( AllTrim( cFile ) )
               If aScan( aPrgFiles, cFile ) == 0
                  aAdd( aPrgFiles, cFile )
               EndIf
            ElseIf ::SearchTypeAdd( ::SearchItem( cFile, 'RC module' ) ) == 'RC module' .and. cFile <> 'RC module'
               cFile := Upper( AllTrim( cFile ) )
               If aScan( aRcFiles, cFile ) == 0
                  aAdd( aRcFiles, cFile )
               EndIf
            EndIf
         Next i
         nPrgFiles := Len( aPrgFiles )
         If nPrgFiles == 0
            waitmess:Hide()
            MsgStop( 'Project has no .PRG files.', 'ooHG IDE+' )
            Break
         EndIf

         // Build make script
         // Variables
         cOut := ''
         cOut += 'PROJECTFOLDER = ' + DelSlash( cProjFolder ) + CRLF
         cOut += 'APP_NAME      = ' + cExe + CRLF
         cOut += 'OBJ_DIR       = ' + cProjFolder + 'OBJ' + CRLF
         cOut += 'OBJECTS       = '
         For i := 1 To nPrgFiles
            cOut += '\' + CRLF + '$(OBJ_DIR)\' + aPrgFiles[i] + '.obj '
         Next i
         cOut += CRLF
         cOut += 'RESFILES      = '
         For i := 1 to Len( aRcFiles )
            cOut += '\' + CRLF + '$(OBJ_DIR)\' + aRcFiles[i] + '.res '
         Next i
         cOut += '\' + CRLF + cMiniGUIFolder + 'RESOURCES\oohg.res' + CRLF
         cOut += 'LINK_EXE      = ' + cCompFolder + 'BIN\ILINK32.EXE' + CRLF
         cOut += 'LINK_FLAGS    = -Gn -Tpe -x' + If( nOption == 2, "-ap", "-aa" ) + CRLF
         cOut += 'LINK_SEARCH   = -L' + DelSlash( cProjFolder ) + ;
                                ' -L' + cCompFolder + 'LIB' + ;
                                ' -L' + cHarbourFolder + If( File( cHarbourFolder + 'LIB\WIN\BCC\rtl.lib' ), 'LIB\WIN\BCC', 'LIB' ) + ;
                                ' -L' + cMiniGUIFolder + If( File( cMiniGUIFolder + 'LIB\HB\BCC\oohg.lib' ), 'LIB\HB\BCC', 'LIB' ) + CRLF
         cOut += 'LINK_LIBS     = '
         If File( cMiniGuiFolder + 'LIB\HB\BCC\oohg.lib' )
           cOut += '\' + CRLF + cMiniGuiFolder + 'LIB\HB\BCC\oohg.lib'
           cOut += '\' + CRLF + cMiniGuiFolder + 'LIB\HB\BCC\hbprinter.lib'
           cOut += '\' + CRLF + cMiniGuiFolder + 'LIB\HB\BCC\miniprint.lib'
         Else
           cOut += '\' + CRLF + cMiniGuiFolder + 'LIB\oohg.lib'
           cOut += '\' + CRLF + cMiniGuiFolder + 'LIB\hbprinter.lib'
           cOut += '\' + CRLF + cMiniGuiFolder + 'LIB\miniprint.lib'
         EndIf
         If nOption == 2
            cOut += '\' + CRLF + cHarbourFolder + 'LIB\gtwin.lib'
         EndIf
         cOut += '\' + CRLF + cHarbourFolder + 'LIB\gtgui.lib'
         For Each i In { "ace32.lib", ;
                         "codepage.lib", ;
                         "common.lib", ;
                         "ct.lib", ;
                         "dbfcdx.lib", ;
                         "dbfdbt.lib", ;
                         "dbffpt.lib", ;
                         "dbfntx.lib", ;
                         "debug.lib", ;
                         "dll.lib", ;
                         "hbcommon.lib", ;
                         "hbcpage.lib", ;
                         "hbct.lib", ;
                         "hbdebug.lib", ;
                         "hbhsx.lib", ;
                         "hblang.lib", ;
                         "hbmacro.lib", ;
                         "hbodbc.lib", ;
                         "hboleaut.lib", ;
                         "hbpp.lib", ;
                         "hbrdd.lib", ;
                         "hbrtl.lib", ;
                         "hbsix.lib", ;
                         "hbvm.lib", ;
                         "hbwin.lib", ;
                         "hsx.lib", ;
                         "lang.lib", ;
                         "libmisc.lib", ;
                         "libmysqldll.lib", ;
                         "macro.lib", ;
                         "mysql.lib", ;
                         "odbc32.lib", ;
                         "pcrepos.lib", ;
                         "pp.lib", ;
                         "rdd.lib", ;
                         "rddads.lib", ;
                         "rddcdx.lib", ;
                         "rddfpt.lib", ;
                         "rddntx.lib", ;
                         "rtl.lib", ;
                         "tip.lib", ;
                         "vm.lib", ;
                         "xhb.lib", ;
                         "ziparchive.lib", ;
                         "zlib1.lib" }
            If File( cHarbourFolder + 'LIB\' + i )
               cOut += '\' + CRLF + cHarbourFolder + 'LIB\' + i
            EndIf
         Next
         cOut += CRLF
         cOut += 'CC_EXE        = ' + cCompFolder + 'BIN\BCC32.EXE' + CRLF
         cOut += 'CC_FLAGS      = -c -O2 -tW -M' + CRLF
         cOut += 'CC_SEARCH     = -I' + DelSlash( cProjFolder ) + ';' + ;
                                        cCompFolder + 'INCLUDE;' + ;
                                        cHarbourFolder + 'INCLUDE;' + ;
                                        cMiniGUIFolder + 'INCLUDE;' + ;
                                 '-L' + cCompFolder + 'LIB;' + CRLF
         cOut += 'HRB_EXE       = ' + cHarbourFolder + 'BIN\HARBOUR.EXE' + CRLF
         cOut += 'HRB_FLAGS     = -n -q ' + If( nOption == 2, "-b ", "" ) + CRLF
         cOut += 'HRB_SEARCH    = -i' + DelSlash( cProjFolder ) + ;
                                ' -i' + cHarbourFolder + 'INCLUDE' + ;
                                ' -i' + cMiniGUIFolder + 'INCLUDE' + CRLF
         cOut += 'RC_COMP       = ' + cCompFolder + 'BIN\BRC32.EXE' + CRLF
         cOut += CRLF
         // Rule for .exe building
         cOut += '$(APP_NAME) : $(OBJECTS) $(RESFILES)' + CRLF
         cOut += HTAB + '$(LINK_EXE) $(LINK_SEARCH) $(LINK_FLAGS) c0w32.obj $(OBJECTS),$(APP_NAME),,$(LINK_LIBS) cw32.lib import32.lib,,$(RESFILES)' + CRLF
         cOut += HTAB + '@echo.' + CRLF
         cOut += CRLF
         // Rule for .c compiling
         For i := 1 To nPrgFiles
            cOut += '$(OBJ_DIR)\' + aPrgFiles[i] + '.obj : $(OBJ_DIR)\' + aPrgFiles[i] + '.c' + CRLF
            cOut += HTAB + '$(CC_EXE) $(CC_FLAGS) $(CC_SEARCH) -o$@ $**' + CRLF
            cOut += HTAB + '@echo.' + CRLF
            cOut += CRLF
         Next i
         // Rule for .prg compiling
         For i := 1 To nPrgFiles
            cOut += '$(OBJ_DIR)\' + aPrgFiles[i] + '.c : $(PROJECTFOLDER)\' + aPrgFiles[i] + '.prg' + CRLF
            cOut += HTAB + '$(HRB_EXE) $(HRB_FLAGS) $(HRB_SEARCH) $** -o$@' + CRLF
            cOut += HTAB + '@echo.' + CRLF
            cOut += CRLF
         Next i
         // Rule for .rc compiling
         For i := 1 to Len( aRcFiles )
            cOut += '$(OBJ_DIR)\' + aRcFiles[i] + '.res : $(PROJECTFOLDER)\' + aRcFiles[i] + '.rc' + CRLF
            cOut += HTAB + '$(RC_COMP) -r -fo$@ $**' + CRLF
            cOut += HTAB + '@echo.' + CRLF
         Next i
         cOut += cMiniGUIFolder + 'RESOURCES\oohg.res : ' + cMiniGUIFolder + 'RESOURCES\oohg_bcc.rc' + CRLF
         cOut += HTAB + '$(RC_COMP) -r -fo$@ $**' + CRLF
         cOut += HTAB + '@echo.' + CRLF
         // Write make script
         MemoWrit( '_temp.bc', cOut )

         // Build batch to launch make utility
         cOut := ''
         cOut += '@echo off' + CRLF
         cOut += cCompFolder + 'BIN\MAKE.EXE /f' + cProjFolder + '_temp.bc > ' + cProjFolder + 'error.lst' + CRLF
         MemoWrit( '_build.bat', cOut )

         // Create temp folder for objects
         CreateFolder( cProjFolder + 'OBJ' )

         // Compile and link
         EXECUTE FILE '_build.bat' WAIT HIDE

      Case ::lTBuild == 1 // Compile.bat

         // Check for compile file
         If ! File( 'compile.bat' ) .and. ! IsFileInPath( 'compile.bat' )
            waitmess:Hide()
            MsgInfo( 'Copy file COMPILE.BAT from ooHG root folder to the current' + CRLF + 'project folder, or add ooHG root folder to PATH.', 'ooHG IDE+' )
            Break
         EndIf

         // Build auxiliary source file
         nItems := Form_Tree:Tree_1:ItemCount
         aPrgFiles := {}
         For i := 1 To nItems
            cFile := Form_Tree:Tree_1:Item( i )
            If ::SearchTypeAdd( ::SearchItem( cFile, 'Prg module' ) ) == 'Prg module' .and. cFile <> 'Prg module'
               cFile := Upper( AllTrim( cFile + '.PRG' ) )
               If aScan( aPrgFiles, cFile ) == 0
                  aAdd( aPrgFiles, cFile )
               EndIf
            EndIf
         Next i
         nPrgFiles := Len( aPrgFiles )
         If nPrgFiles == 0
            waitmess:Hide()
            MsgStop( 'Project has no .PRG files.', 'ooHG IDE+' )
            Break
         EndIf
         cOut := ''
         For i := 1 To nPrgFiles
            cOut += "# include '" + aPrgFiles[i] + "'" + CRLF + CRLF
         Next i
         MemoWrit( cPrgName + '.prg', cOut )

         // Compile and link
         cDosComm := '/c compile ' + cPrgName + ' /nr /l' + If( nOption == 2, " /d", "" )
         EXECUTE FILE 'CMD.EXE' PARAMETERS cDosComm HIDE

      EndCase

      // Check for errors
      cError := MemoRead( 'error.lst' )
      cError1 := Upper( cError )
      If At( 'ERROR', cError1 ) > 0 .or. At( 'FATAL', cError1 ) > 0 .or. At( 'LD RETURNED 1 EXIT STATUS', cError1 ) > 0
         waitmess:Hide()
         ::ViewErrors( cError )
         Break
      ElseIf ! File( cExe )
         waitmess:Hide()
         MsgStop( 'EXE is missing.', 'ooHG IDE+' )
         Break
      EndIf

      // Rename or move
      If ! Empty( ::cOutFile )
         cOut := Upper( AllTrim( ::cOutFile ) )
         If Right( cOut, 4 ) != ".EXE"
            cOut += ".EXE"
         EndIf
         cDosComm := '/c move ' + cExe + ' ' + cOut
         EXECUTE FILE 'CMD.EXE' PARAMETERS cDosComm HIDE
         If ! File( cOut )
            waitmess:Hide()
            MsgStop( "Can't move or rename EXE file.", 'ooHG IDE+' )
            Break
         EndIf
         cExe := cOut
      EndIf

      // Cleanup
      BorraTemp( cProjFolder )
      waitmess:Hide()
      If nOption == 0
         MsgInfo( 'Project builded.', 'ooHG IDE+' )
      ElseIf nOption == 1 .or. nOption == 2
         EXECUTE FILE cExe
      EndIf
   End Sequence

   CursorArrow()
   Form_Tree:button_9:Enabled := .T.
   Form_Tree:button_10:Enabled := .T.
   Form_Tree:button_11:Enabled := .T.
Return

*-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._-._.-._.-._.-._.-._.-._.-._
*                  COMPILING CON BORLAND C Y XHARBOUR
*-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._-._.-._.-._.-._.-._.-._.-._

//------------------------------------------------------------------------------
METHOD xBuildBCC( nOption ) CLASS THMI
//------------------------------------------------------------------------------
   Local aPrgFiles
   Local aRcFiles
   Local cCompFolder := ::cBCCFolder + '\'
   Local cDosComm
   Local cError
   Local cError1
   Local cExe
   Local cFile
   Local cHarbourFolder := ::cxHbBCCFolder + '\'
   Local cMiniGuiFolder := ::cGuixHbBCC + '\'
   Local cOut
   Local cPrgName
   Local cProjFolder := ::cProjFolder + '\'
   Local i
   Local nItems
   Local nPrgFiles

   Form_Tree:button_9:Enabled := .F.
   Form_Tree:button_10:Enabled := .F.
   Form_Tree:button_11:Enabled := .F.
   CursorWait()
   waitmess:hmi_label_101:Value := 'Compiling ...'
   waitmess:Show()

   Begin Sequence
      // Check folders
      If Empty( ::cProjectName )
         waitmess:Hide()
         MsgStop( 'You must save the project before building it.', 'ooHG IDE+' )
         Break
      EndIf

      If Empty( cCompFolder )
         waitmess:Hide()
         MsgStop( 'The BCC folder must be specified to build a project.', 'ooHG IDE+' )
         Break
      EndIf

      If Empty( cMiniGuiFolder )
         waitmess:Hide()
         MsgStop( 'The ooHG-xHb-BCC folder must be specified to build a project.', 'ooHG IDE+' )
         Break
      EndIf

      If Empty( cHarbourFolder )
         waitmess:Hide()
         MsgStop( 'The xHarbour-Borland C folder must be specified to build a project.', 'ooHG IDE+' )
         Break
      EndIf

      // Prepare to build
      SetCurrentFolder( cProjFolder )
      BorraTemp( cProjFolder )
      cPrgName := StrTran( AllTrim( DelExt( DelPath( ::cProjectName ) ) ), " ", "_" )
      cExe := cPrgName + '.exe'
      If File( cExe )
         DELETE FILE ( cExe )
      EndIf
      If File( cExe )
         waitmess:Hide()
         MsgInfo( 'Error building project.' + CRLF + 'Is EXE running?', 'ooHG IDE+' )
         Break
      EndIf

      Do Case
      Case ::lTBuild == 2    // Own Make

         // Build list of source files
         nItems := Form_Tree:Tree_1:ItemCount
         aPrgFiles := {}
         aRcFiles := {}
         For i := 1 To nItems
            cFile := Form_Tree:Tree_1:Item( i )
            If ::SearchTypeAdd( ::SearchItem( cFile, 'Prg module' ) ) == 'Prg module' .and. cFile <> 'Prg module'
               cFile := Upper( AllTrim( cFile ) )
               If aScan( aPrgFiles, cFile ) == 0
                  aAdd( aPrgFiles, cFile )
               EndIf
            ElseIf ::SearchTypeAdd( ::SearchItem( cFile, 'RC module' ) ) == 'RC module' .and. cFile <> 'RC module'
               cFile := Upper( AllTrim( cFile ) )
               If aScan( aRcFiles, cFile ) == 0
                  aAdd( aRcFiles, cFile )
               EndIf
            EndIf
         Next i
         nPrgFiles := Len( aPrgFiles )
         If nPrgFiles == 0
            waitmess:Hide()
            MsgStop( 'Project has no .PRG files.', 'ooHG IDE+' )
            Break
         EndIf

         // Build make script
         // Variables
         cOut := ''
         cOut += 'PROJECTFOLDER = ' + DelSlash( cProjFolder ) + CRLF
         cOut += 'APP_NAME      = ' + cExe + CRLF
         cOut += 'TDS_NAME      = ' + cPrgName + '.tds' + CRLF
         cOut += 'OBJ_DIR       = ' + cProjFolder + 'OBJ' + CRLF
         cOut += 'OBJECTS       = '
         For i := 1 To nPrgFiles
            cOut += '\' + CRLF + '$(OBJ_DIR)\' + aPrgFiles[i] + '.obj '
         Next i
         cOut += CRLF
         cOut += 'RESFILES      = '
         For i := 1 to Len( aRcFiles )
            cOut += '\' + CRLF + '$(OBJ_DIR)\' + aRcFiles[i] + '.res '
         Next i
         cOut += '\' + CRLF + cMiniGUIFolder + 'RESOURCES\oohg.res' + CRLF
         cOut += 'LINK_EXE      = ' + cCompFolder + 'BIN\ILINK32.EXE' + CRLF
         cOut += 'LINK_FLAGS    = -Gn -Tpe -x ' + If( nOption == 2, "-ap", "-aa" ) + CRLF
         cOut += 'LINK_SEARCH   = -L' + DelSlash( cProjFolder ) + ;
                                ' -L' + cCompFolder + 'LIB' + ;
                                ' -L' + cHarbourFolder + If( File( cHarbourFolder + 'LIB\WIN\BCC\rtl.lib' ), 'LIB\WIN\BCC', 'LIB' ) + ;
                                ' -L' + cMiniGUIFolder + If( File( cMiniGUIFolder + 'LIB\XHB\BCC\oohg.lib' ), 'LIB\XHB\BCC', 'LIB' ) + CRLF
         cOut += 'LINK_LIBS     = '
         If File( cMiniGuiFolder + 'LIB\XHB\BCC\oohg.lib' )
           cOut += '\' + CRLF + cMiniGuiFolder + 'LIB\XHB\BCC\oohg.lib'
           cOut += '\' + CRLF + cMiniGuiFolder + 'LIB\XHB\BCC\hbprinter.lib'
           cOut += '\' + CRLF + cMiniGuiFolder + 'LIB\XHB\BCC\miniprint.lib'
         Else
           cOut += '\' + CRLF + cMiniGuiFolder + 'LIB\oohg.lib'
           cOut += '\' + CRLF + cMiniGuiFolder + 'LIB\hbprinter.lib'
           cOut += '\' + CRLF + cMiniGuiFolder + 'LIB\miniprint.lib'
         EndIf
         If nOption == 2
            cOut += '\' + CRLF + cHarbourFolder + 'LIB\gtwin.lib'
         EndIf
         cOut += '\' + CRLF + cHarbourFolder + 'LIB\gtgui.lib'
         For Each i In { "ace32.lib", ;
                         "codepage.lib", ;
                         "common.lib", ;
                         "ct.lib", ;
                         "dbfcdx.lib", ;
                         "dbfdbt.lib", ;
                         "dbffpt.lib", ;
                         "dbfntx.lib", ;
                         "debug.lib", ;
                         "dll.lib", ;
                         "hbcommon.lib", ;
                         "hbcpage.lib", ;
                         "hbct.lib", ;
                         "hbdebug.lib", ;
                         "hbhsx.lib", ;
                         "hblang.lib", ;
                         "hbmacro.lib", ;
                         "hbodbc.lib", ;
                         "hboleaut.lib", ;
                         "hbpp.lib", ;
                         "hbrdd.lib", ;
                         "hbrtl.lib", ;
                         "hbsix.lib", ;
                         "hbvm.lib", ;
                         "hbwin.lib", ;
                         "hsx.lib", ;
                         "lang.lib", ;
                         "libmisc.lib", ;
                         "libmysqldll.lib", ;
                         "macro.lib", ;
                         "mysql.lib", ;
                         "odbc32.lib", ;
                         "pcrepos.lib", ;
                         "pp.lib", ;
                         "rdd.lib", ;
                         "rddads.lib", ;
                         "rddcdx.lib", ;
                         "rddfpt.lib", ;
                         "rddntx.lib", ;
                         "rtl.lib", ;
                         "tip.lib", ;
                         "vm.lib", ;
                         "xhb.lib", ;
                         "ziparchive.lib", ;
                         "zlib1.lib" }
            If File( cHarbourFolder + 'LIB\' + i )
               cOut += '\' + CRLF + cHarbourFolder + 'LIB\' + i
            EndIf
         Next
         cOut += CRLF
         cOut += 'CC_EXE        = ' + cCompFolder + 'BIN\BCC32.EXE' + CRLF
         cOut += 'CC_FLAGS      = -c -O2 -tW -M' + CRLF
         cOut += 'CC_SEARCH     = -I' + DelSlash( cProjFolder ) + ';' + ;
                                        cCompFolder + 'INCLUDE;' + ;
                                        cHarbourFolder + 'INCLUDE;' + ;
                                        cMiniGUIFolder + 'INCLUDE;' + ;
                                 '-L' + cCompFolder + 'LIB;' + CRLF
         cOut += 'HRB_EXE       = ' + cHarbourFolder + 'BIN\HARBOUR.EXE' + CRLF
         cOut += 'HRB_FLAGS     = -n -q ' + If( nOption == 2, "-b ", "" ) + CRLF
         cOut += 'HRB_SEARCH    = -i' + DelSlash( cProjFolder ) + ;
                                ' -i' + cHarbourFolder + 'INCLUDE' + ;
                                ' -i' + cMiniGUIFolder + 'INCLUDE' + CRLF
         cOut += 'RC_COMP       = ' + cCompFolder + 'BIN\BRC32.EXE' + CRLF
         cOut += CRLF
         // Rule for .exe building
         cOut += '$(APP_NAME) : $(OBJECTS) $(RESFILES)' + CRLF
         cOut += HTAB + '$(LINK_EXE) $(LINK_SEARCH) $(LINK_FLAGS) c0w32.obj $(OBJECTS),$(APP_NAME),,$(LINK_LIBS) cw32.lib import32.lib,,$(RESFILES)' + CRLF
         cOut += HTAB + '@del $(TDS_NAME)' + CRLF
         cOut += HTAB + '@echo.' + CRLF
         cOut += CRLF
         // Rule for .c compiling
         For i := 1 To nPrgFiles
            cOut += '$(OBJ_DIR)\' + aPrgFiles[i] + '.obj : $(OBJ_DIR)\' + aPrgFiles[i] + '.c' + CRLF
            cOut += HTAB + '$(CC_EXE) $(CC_FLAGS) $(CC_SEARCH) -o$@ $**' + CRLF
            cOut += HTAB + '@echo.' + CRLF
            cOut += CRLF
         Next i
         // Rule for .prg compiling
         For i := 1 To nPrgFiles
            cOut += '$(OBJ_DIR)\' + aPrgFiles[i] + '.c : $(PROJECTFOLDER)\' + aPrgFiles[i] + '.prg' + CRLF
            cOut += HTAB + '$(HRB_EXE) $(HRB_FLAGS) $(HRB_SEARCH) $** -o$@' + CRLF
            cOut += HTAB + '@echo.' + CRLF
            cOut += CRLF
         Next i
         // Rule for .rc compiling
         For i := 1 to Len( aRcFiles )
            cOut += '$(OBJ_DIR)\' + aRcFiles[i] + '.res : $(PROJECTFOLDER)\' + aRcFiles[i] + '.rc' + CRLF
            cOut += HTAB + '$(RC_COMP) -r -fo$@ $**' + CRLF
            cOut += HTAB + '@echo.' + CRLF
         Next i
         cOut += cMiniGUIFolder + 'RESOURCES\oohg.res : ' + cMiniGUIFolder + 'RESOURCES\oohg_bcc.rc' + CRLF
         cOut += HTAB + '$(RC_COMP) -r -fo$@ $**' + CRLF
         cOut += HTAB + '@echo.' + CRLF
         // Write make script
         MemoWrit( '_temp.bc', cOut )

         // Build batch to launch make utility
         cOut := ''
         cOut += '@echo off' + CRLF
         cOut += cCompFolder + 'BIN\MAKE.EXE /f' + cProjFolder + '_temp.bc > ' + cProjFolder + 'error.lst' + CRLF
         MemoWrit( '_build.bat', cOut )

         // Create temp folder for objects
         CreateFolder( cProjFolder + 'OBJ' )

         // Compile and link
         EXECUTE FILE '_build.bat' WAIT HIDE

      Case ::lTBuild == 1 // Compile.bat

         // Check for compile file
         If ! File( 'compile.bat' ) .and. ! IsFileInPath( 'compile.bat' )
            waitmess:Hide()
            MsgInfo( 'Copy file COMPILE.BAT from ooHG root folder to the current' + CRLF + 'project folder, or add ooHG root folder to PATH.', 'ooHG IDE+' )
            Break
         EndIf

         // Build auxiliary source file
         nItems := Form_Tree:Tree_1:ItemCount
         aPrgFiles := {}
         For i := 1 To nItems
            cFile := Form_Tree:Tree_1:Item( i )
            If ::SearchTypeAdd( ::SearchItem( cFile, 'Prg module' ) ) == 'Prg module' .and. cFile <> 'Prg module'
               cFile := Upper( AllTrim( cFile + '.PRG' ) )
               If aScan( aPrgFiles, cFile ) == 0
                  aAdd( aPrgFiles, cFile )
               EndIf
            EndIf
         Next i
         nPrgFiles := Len( aPrgFiles )
         If nPrgFiles == 0
            waitmess:Hide()
            MsgStop( 'Project has no .PRG files.', 'ooHG IDE+' )
            Break
         EndIf
         cOut := ''
         For i := 1 To nPrgFiles
            cOut += "# include '" + aPrgFiles[i] + "'" + CRLF + CRLF
         Next i
         MemoWrit( cPrgName + '.prg', cOut )

         // Compile and link
         cDosComm := '/c compile ' + cPrgName + ' /nr /l' + If( nOption == 2, " /d", "" )
         EXECUTE FILE 'CMD.EXE' PARAMETERS cDosComm HIDE

      EndCase

      // Check for errors
      cError := MemoRead( 'error.lst' )
      cError1 := Upper( cError )
      If At( 'ERROR', cError1 ) > 0 .or. At( 'FATAL', cError1 ) > 0 .or. At( 'LD RETURNED 1 EXIT STATUS', cError1 ) > 0
         waitmess:Hide()
         ::ViewErrors( cError )
         Break
      ElseIf ! File( cExe )
         waitmess:Hide()
         MsgStop( 'EXE is missing.', 'ooHG IDE+' )
         Break
      EndIf

      // Rename or move
      If ! Empty( ::cOutFile )
         cOut := Upper( AllTrim( ::cOutFile ) )
         If Right( cOut, 4 ) != ".EXE"
            cOut += ".EXE"
         EndIf
         cDosComm := '/c move ' + cExe + ' ' + cOut
         EXECUTE FILE 'CMD.EXE' PARAMETERS cDosComm HIDE
         If ! File( cOut )
            waitmess:Hide()
            MsgStop( "Can't move or rename EXE file.", 'ooHG IDE+' )
            Break
         EndIf
         cExe := cOut
      EndIf

      // Cleanup
      BorraTemp( cProjFolder )
      waitmess:Hide()
      If nOption == 0
         MsgInfo( 'Project builded.', 'ooHG IDE+' )
      ElseIf nOption == 1 .or. nOption == 2
         EXECUTE FILE cExe
      EndIf
   End Sequence

   CursorArrow()
   Form_Tree:button_9:Enabled := .T.
   Form_Tree:button_10:Enabled := .T.
   Form_Tree:button_11:Enabled := .T.
Return

*-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._-._.-._.-._.-._.-._.-._.-._
*                 COMPILING WITH PELLES C AND XHARBOUR
*-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._-._.-._.-._.-._.-._.-._.-._

//------------------------------------------------------------------------------
METHOD XBldPellC( nOption ) CLASS THMI
//------------------------------------------------------------------------------
   Local aPrgFiles
   Local aRcFiles
   Local cCompFolder := ::cPellFolder + '\'
   Local cDosComm
   Local cError
   Local cError1
   Local cExe
   Local cFile
   Local cHarbourFolder := ::cxHbPellFolder + '\'
   Local cMiniGuiFolder := ::cGuixHbPelles + '\'
   Local cOut
   Local cPrgName
   Local cProjFolder := ::cProjFolder + '\'
   Local i
   Local nItems
   Local nPrgFiles

   Form_Tree:button_9:Enabled := .F.
   Form_Tree:button_10:Enabled := .F.
   Form_Tree:button_11:Enabled := .F.
   CursorWait()
   waitmess:hmi_label_101:Value := 'Compiling ...'
   waitmess:Show()

   Begin Sequence
      // Check folders
      If Empty( ::cProjectName )
         waitmess:Hide()
         MsgStop( 'You must save the project before building it.', 'ooHG IDE+' )
         Break
      EndIf

      If Empty( cCompFolder )
         waitmess:Hide()
         MsgStop( 'The Pelles C folder must be specified to build a project.', 'ooHG IDE+' )
         Break
      EndIf

      If Empty( cMiniGuiFolder )
         waitmess:Hide()
         MsgStop( 'The ooHG-xHb-Pelles C folder must be specified to build a project.', 'ooHG IDE+' )
         Break
      EndIf

      If Empty( cHarbourFolder )
         waitmess:Hide()
         MsgStop( 'The xHarbour-Pelles C folder must be specified to build a project.', 'ooHG IDE+' )
         Break
      EndIf

      // Prepare to build
      SetCurrentFolder( cProjFolder )
      BorraTemp( cProjFolder )
      cPrgName := StrTran( AllTrim( DelExt( DelPath( ::cProjectName ) ) ), " ", "_" )
      cExe := cPrgName + '.exe'
      If File( cExe )
         DELETE FILE ( cExe )
      EndIf
      If File( cExe )
         waitmess:Hide()
         MsgInfo( 'Error building project.' + CRLF + 'Is EXE running?', 'ooHG IDE+' )
         Break
      EndIf

      Do Case
      Case ::lTBuild == 2    // Own Make

         // Build list of source files
         nItems := Form_Tree:Tree_1:ItemCount
         aPrgFiles := {}
         aRcFiles := {}
         For i := 1 To nItems
            cFile := Form_Tree:Tree_1:Item( i )
            If ::SearchTypeAdd( ::SearchItem( cFile, 'Prg module' ) ) == 'Prg module' .and. cFile <> 'Prg module'
               cFile := Upper( AllTrim( cFile ) )
               If aScan( aPrgFiles, cFile ) == 0
                  aAdd( aPrgFiles, cFile )
               EndIf
            ElseIf ::SearchTypeAdd( ::SearchItem( cFile, 'RC module' ) ) == 'RC module' .and. cFile <> 'RC module'
               cFile := Upper( AllTrim( cFile ) )
               If aScan( aRcFiles, cFile ) == 0
                  aAdd( aRcFiles, cFile )
               EndIf
            EndIf
         Next i
         nPrgFiles := Len( aPrgFiles )
         If nPrgFiles == 0
            waitmess:Hide()
            MsgStop( 'Project has no .PRG files.', 'ooHG IDE+' )
            Break
         EndIf

         // Build make script
         cOut := ''
         cOut += 'HARBOUR_EXE = ' + cHarbourFolder + 'BIN\HARBOUR.EXE' + CRLF
         cOut += 'CC = ' + cCompFolder + 'BIN\POCC.EXE' + CRLF
         cOut += 'ILINK_EXE = ' + cCompFolder + 'BIN\POLINK.EXE' + CRLF
         cOut += 'BRC_EXE = ' + cCompFolder + 'BIN\PORC.EXE' + CRLF
         cOut += 'APP_NAME = ' + cExe + CRLF
         cOut += 'INCLUDE_DIR = ' + cHarbourFolder + 'INCLUDE;' + cMiniGuiFolder + 'INCLUDE;' + DelSlash( cProjFolder ) + CRLF
         cOut += 'INCLUDE_C_DIR = ' + cHarbourFolder + 'INCLUDE -I' + cMiniGuiFolder + 'INCLUDE -I' + DelSlash( cProjFolder ) + ' -I' + cCompFolder + 'INCLUDE -I' + cCompFolder + 'INCLUDE\WIN' + CRLF
         cOut += 'CC_LIB_DIR = ' + cCompFolder + 'LIB' + CRLF
         cOut += 'HRB_LIB_DIR = ' + cHarbourFolder + 'LIB' + CRLF
         cOut += 'OBJ_DIR = ' + cProjFolder + 'OBJ' + CRLF
         cOut += 'C_DIR = ' + cProjFolder + 'OBJ' + CRLF
         cOut += 'USER_FLAGS =' + CRLF
         cOut += 'HARBOUR_FLAGS = /i$(INCLUDE_DIR) /n /q0 ' + If( nOption == 2, "/b ", "" ) + '$(USER_FLAGS)' + CRLF
         cOut += 'COBJFLAGS = /Ze /Zx /Go /Tx86-coff /D__WIN32__ ' + '-I$(INCLUDE_C_DIR)' + CRLF
         cOut += CRLF
         cOut += '$(APP_NAME) : $(OBJ_DIR)\' + aPrgFiles[1] + '.obj'
         For i := 2 To nPrgFiles
            cOut += ' \' + CRLF
            cOut += '   $(OBJ_DIR)\' + aPrgFiles[i] + '.obj'
         Next i
         cOut += CRLF
         For i := 1 to Len( aRcFiles )
            cOut += '   $(BRC_EXE) /fo' + aRcFiles[i] + '.res ' + aRcFiles[i] + '.rc' + CRLF
         Next i
         For i := 1 To nPrgFiles
            cOut += '   echo $(OBJ_DIR)\' + aPrgFiles[i] + '.obj + >' + If( i > 1, '>', '' ) + 'b32.bc' + CRLF
         Next i
         cOut += '   echo /OUT:$(APP_NAME) >> b32.bc' + CRLF
         cOut += '   echo /FORCE:MULTIPLE >> b32.bc' + CRLF
         cOut += '   echo /LIBPATH:$(CC_LIB_DIR) >> b32.bc' + CRLF
         cOut += '   echo /LIBPATH:$(CC_LIB_DIR)\WIN >> b32.bc' + CRLF
         If File( cMiniGuiFolder + 'LIB\XHB\PCC\oohg.lib' )
           cOut += '   echo ' + cMiniGuiFolder  + 'LIB\XHB\BCC\oohg.lib >> b32.bc' + CRLF
         Else
           cOut += '   echo ' + cMiniGuiFolder  + 'LIB\oohg.lib >> b32.bc' + CRLF
         EndIf
         If File( cMiniGuiFolder + 'LIB\XHB\PCC\hbprinter.lib' )
           cOut += '   echo ' + cMiniGuiFolder  + 'LIB\XHB\BCC\hbprinter.lib >> b32.bc' + CRLF
         Else
           cOut += '   echo ' + cMiniGuiFolder  + 'LIB\hbprinter.lib >> b32.bc' + CRLF
         EndIf
         If File( cMiniGuiFolder + 'LIB\XHB\PCC\miniprint.lib' )
           cOut += '   echo ' + cMiniGuiFolder  + 'LIB\XHB\BCC\miniprint.lib >> b32.bc' + CRLF
         Else
           cOut += '   echo ' + cMiniGuiFolder  + 'LIB\miniprint.lib >> b32.bc' + CRLF
         EndIf
         If nOption == 2
            cOut += '   echo $(HRB_LIB_DIR)\gtwin.lib >> b32.bc' + CRLF
         EndIf
         cOut += '   echo $(HRB_LIB_DIR)\gtgui.lib >> b32.bc' + CRLF
         For Each i In { "ace32.lib", ;
                         "codepage.lib", ;
                         "common.lib", ;
                         "ct.lib", ;
                         "dbfcdx.lib", ;
                         "dbfdbt.lib", ;
                         "dbffpt.lib", ;
                         "dbfntx.lib", ;
                         "debug.lib", ;
                         "dll.lib", ;
                         "hbcommon.lib", ;
                         "hbcpage.lib", ;
                         "hbct.lib", ;
                         "hbdebug.lib", ;
                         "hbhsx.lib", ;
                         "hblang.lib", ;
                         "hbmacro.lib", ;
                         "hbodbc.lib", ;
                         "hboleaut.lib", ;
                         "hbpp.lib", ;
                         "hbrdd.lib", ;
                         "hbrtl.lib", ;
                         "hbsix.lib", ;
                         "hbvm.lib", ;
                         "hbwin.lib", ;
                         "hsx.lib", ;
                         "lang.lib", ;
                         "libmisc.lib", ;
                         "libmysqldll.lib", ;
                         "macro.lib", ;
                         "mysql.lib", ;
                         "odbc32.lib", ;
                         "pcrepos.lib", ;
                         "pp.lib", ;
                         "rdd.lib", ;
                         "rddads.lib", ;
                         "rddcdx.lib", ;
                         "rddfpt.lib", ;
                         "rddntx.lib", ;
                         "rtl.lib", ;
                         "tip.lib", ;
                         "vm.lib", ;
                         "xhb.lib", ;
                         "ziparchive.lib", ;
                         "zlib1.lib" }
            If File( cHarbourFolder + 'LIB\' + i )
               cOut += '   echo $(HRB_LIB_DIR)\' + i + ' >> b32.bc' + CRLF
            EndIf
         Next
         cOut += '   echo $(CC_LIB_DIR)\crt.lib >> b32.bc' + CRLF
         For Each i In { "kernel32.lib", ;
                         "winspool.lib", ;
                         "user32.lib", ;
                         "advapi32.lib", ;
                         "ole32.lib", ;
                         "uuid.lib", ;
                         "oleaut32.lib", ;
                         "mpr.lib", ;
                         "comdlg32.lib", ;
                         "comctl32.lib", ;
                         "gdi32.lib", ;
                         "olepro32.lib", ;
                         "shell32.lib", ;
                         "winmm.lib", ;
                         "vfw32.lib", ;
                         "wsock32.lib" }
            If File( cHarbourFolder + 'LIB\' + i )
               cOut += '   echo ' + i + ' >> b32.bc' + CRLF
            EndIf
         Next
         For i := 1 to Len( aRcFiles )
            cOut += '   echo ' + aRcFiles[i] + '.res >> b32.bc' + CRLF
         Next i
         cOut += '   echo ' + cMiniGUIFolder + 'resources\oohg.res >> b32.bc' + CRLF
         cOut += '   $(ILINK_EXE)  /SUBSYSTEM:' + If( nOption == 2, "CONSOLE", "WINDOWS" ) + ' @b32.bc' + CRLF
         cOut += CRLF
         For i := 1 To nPrgFiles
            cOut += CRLF
            cOut += '$(C_DIR)\' + aPrgFiles[i] + '.c : ' + cProjFolder + aPrgFiles[i] + '.prg' + CRLF
            cOut += '   $(HARBOUR_EXE) $(HARBOUR_FLAGS) $** -o$@'  + CRLF
            cOut += CRLF
            cOut += '$(OBJ_DIR)\' + aPrgFiles[i] + '.obj : $(C_DIR)\' + aPrgFiles[i] + '.c' + CRLF
            cOut += '   $(CC) $(COBJFLAGS) -Fo$@ $**' + CRLF
         Next i
         MemoWrit( '_temp.bc', cOut )

         // Build batch
         cOut := ''
         cOut += '@echo off' + CRLF
         cOut += cCompFolder + 'BIN\POMAKE.EXE /F' + cProjFolder + '_temp.bc > ' + cProjFolder + 'error.lst' + CRLF
         MemoWrit( '_build.bat', cOut )

         // Create folder for objects
         CreateFolder( cProjFolder + 'OBJ' )

         // Build
         EXECUTE FILE '_build.bat' WAIT HIDE

   CASE ::ltbuild==1 // Compile.bat

         // Check for compile file
         If ! File( 'compile.bat' ) .and. ! IsFileInPath( 'compile.bat' )
            waitmess:Hide()
            MsgInfo( 'Copy file COMPILE.BAT from ooHG root folder to the current' + CRLF + 'project folder, or add ooHG root folder to PATH.', 'ooHG IDE+' )
            Break
         EndIf

         // Build auxiliary source file
         nItems := Form_Tree:Tree_1:ItemCount
         aPrgFiles := {}
         For i := 1 To nItems
            cFile := Form_Tree:Tree_1:Item( i )
            If ::SearchTypeAdd( ::SearchItem( cFile, 'Prg module' ) ) == 'Prg module' .and. cFile <> 'Prg module'
               cFile := Upper( AllTrim( cFile + '.PRG' ) )
               If aScan( aPrgFiles, cFile ) == 0
                  aAdd( aPrgFiles, cFile )
               EndIf
            EndIf
         Next i
         nPrgFiles := Len( aPrgFiles )
         If nPrgFiles == 0
            waitmess:Hide()
            MsgStop( 'Project has no .PRG files.', 'ooHG IDE+' )
            Break
         EndIf
         cOut := ''
         For i := 1 To nPrgFiles
            cOut += "# include '" + aPrgFiles[i] + "'" + CRLF + CRLF
         Next i
         MemoWrit( cPrgName + '.prg', cOut )

         // Compile and link
         cDosComm := '/c compile ' + cPrgName + ' /nr /l' + If( nOption == 2, " /d", "" )
         EXECUTE FILE 'CMD.EXE' PARAMETERS cDosComm HIDE

      EndCase

      // Check for errors
      cError := MemoRead( 'error.lst' )
      cError1 := Upper( cError )
      If At( 'ERROR', cError1 ) > 0 .or. At( 'FATAL', cError1 ) > 0 .or. At( 'LD RETURNED 1 EXIT STATUS', cError1 ) > 0
         waitmess:Hide()
         ::ViewErrors( cError )
         Break
      ElseIf ! File( cExe )
         waitmess:Hide()
         MsgStop( 'EXE is missing.', 'ooHG IDE+' )
         Break
      EndIf

      // Rename or move
      If ! Empty( ::cOutFile )
         cOut := Upper( AllTrim( ::cOutFile ) )
         If Right( cOut, 4 ) != ".EXE"
            cOut += ".EXE"
         EndIf
         cDosComm := '/c move ' + cExe + ' ' + cOut
         EXECUTE FILE 'CMD.EXE' PARAMETERS cDosComm HIDE
         If ! File( cOut )
            waitmess:Hide()
            MsgStop( "Can't move or rename EXE file.", 'ooHG IDE+' )
            Break
         EndIf
         cExe := cOut
      EndIf

      // Cleanup
      BorraTemp( cProjFolder )
      waitmess:Hide()
      If nOption == 0
         MsgInfo( 'Project builded.', 'ooHG IDE+' )
      ElseIf nOption == 1 .or. nOption == 2
         EXECUTE FILE cExe
      EndIf
   End Sequence

   CursorArrow()
   Form_Tree:button_9:Enabled := .T.
   Form_Tree:button_10:Enabled := .T.
   Form_Tree:button_11:Enabled := .T.
Return


*-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._-._.-._.-._.-._.-._.-._.-._
*                 COMPILING WITH PELLES C AND HARBOUR
*-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._.-._-._.-._.-._.-._.-._.-._.-._

//------------------------------------------------------------------------------
METHOD BldPellC(nOption) CLASS THMI
//------------------------------------------------------------------------------
   Local aPrgFiles
   Local aRcFiles
   Local cCompFolder := ::cPellFolder + '\'
   Local cDosComm
   Local cError
   Local cError1
   Local cExe
   Local cFile
   Local cHarbourFolder := ::cHbPellFolder + '\'
   Local cMiniGuiFolder := ::cGuiHbPelles + '\'
   Local cOut
   Local cPrgName
   Local cProjFolder := ::cProjFolder + '\'
   Local i
   Local nItems
   Local nPrgFiles

   Form_Tree:button_9:Enabled := .F.
   Form_Tree:button_10:Enabled := .F.
   Form_Tree:button_11:Enabled := .F.
   CursorWait()
   waitmess:hmi_label_101:Value := 'Compiling ...'
   waitmess:Show()

   Begin Sequence
      // Check folders
      If Empty( ::cProjectName )
         waitmess:Hide()
         MsgStop( 'You must save the project before building it.', 'ooHG IDE+' )
         Break
      EndIf

      If Empty( cCompFolder )
         waitmess:Hide()
         MsgStop( 'The Pelles C folder must be specified to build a project.', 'ooHG IDE+' )
         Break
      EndIf

      If Empty( cMiniGuiFolder )
         waitmess:Hide()
         MsgStop( 'The ooHG-Hb-Pelles C folder must be specified to build a project.', 'ooHG IDE+' )
         Break
      EndIf

      If Empty( cHarbourFolder )
         waitmess:Hide()
         MsgStop( 'The Harbour-Pelles C folder must be specified to build a project.', 'ooHG IDE+' )
         Break
      EndIf

      // Prepare to build
      SetCurrentFolder( cProjFolder )
      BorraTemp( cProjFolder )
      cPrgName := StrTran( AllTrim( DelExt( DelPath( ::cProjectName ) ) ), " ", "_" )
      cExe := cPrgName + '.exe'
      If File( cExe )
         DELETE FILE ( cExe )
      EndIf
      If File( cExe )
         waitmess:Hide()
         MsgInfo( 'Error building project.' + CRLF + 'Is EXE running?', 'ooHG IDE+' )
         Break
      EndIf

      Do Case
      Case ::lTBuild == 2    // Own Make

         // Build list of source files
         nItems := Form_Tree:Tree_1:ItemCount
         aPrgFiles := {}
         aRcFiles := {}
         For i := 1 To nItems
            cFile := Form_Tree:Tree_1:Item( i )
            If ::SearchTypeAdd( ::SearchItem( cFile, 'Prg module' ) ) == 'Prg module' .and. cFile <> 'Prg module'
               cFile := Upper( AllTrim( cFile ) )
               If aScan( aPrgFiles, cFile ) == 0
                  aAdd( aPrgFiles, cFile )
               EndIf
            ElseIf ::SearchTypeAdd( ::SearchItem( cFile, 'RC module' ) ) == 'RC module' .and. cFile <> 'RC module'
               cFile := Upper( AllTrim( cFile ) )
               If aScan( aRcFiles, cFile ) == 0
                  aAdd( aRcFiles, cFile )
               EndIf
            EndIf
         Next i
         nPrgFiles := Len( aPrgFiles )
         If nPrgFiles == 0
            waitmess:Hide()
            MsgStop( 'Project has no .PRG files.', 'ooHG IDE+' )
            Break
         EndIf

         // Build make script
         cOut := ''
         cOut += 'HARBOUR_EXE = ' + cHarbourFolder + 'BIN\HARBOUR.EXE' + CRLF
         cOut += 'CC = ' + cCompFolder + 'BIN\POCC.EXE' + CRLF
         cOut += 'ILINK_EXE = ' + cCompFolder + 'BIN\POLINK.EXE' + CRLF
         cOut += 'BRC_EXE = ' + cCompFolder + 'BIN\PORC.EXE' + CRLF
         cOut += 'APP_NAME = ' + cExe + CRLF
         cOut += 'INCLUDE_DIR = ' + cHarbourFolder + 'INCLUDE;' + cMiniGuiFolder + 'INCLUDE;' + DelSlash( cProjFolder ) + CRLF
         cOut += 'INCLUDE_C_DIR = ' + cHarbourFolder + 'INCLUDE -I' + cMiniGuiFolder + 'INCLUDE -I' + DelSlash( cProjFolder ) + ' -I' + cCompFolder + 'INCLUDE -I' + cCompFolder + 'INCLUDE\WIN' + CRLF
         cOut += 'CC_LIB_DIR = ' + cCompFolder + 'LIB' + CRLF
         cOut += 'HRB_LIB_DIR = ' + cHarbourFolder + If( File( cHarbourFolder + 'LIB\hbwin.lib' ), 'LIB', 'LIB\WIN\POCC' ) + CRLF
         cOut += 'OBJ_DIR = ' + cProjFolder + 'OBJ' + CRLF
         cOut += 'C_DIR = ' + cProjFolder + 'OBJ' + CRLF
         cOut += 'USER_FLAGS =' + CRLF
         cOut += 'HARBOUR_FLAGS = /i$(INCLUDE_DIR) /n /q0 ' + If( nOption == 2, "/b ", "" ) + '$(USER_FLAGS)' + CRLF
         cOut += 'COBJFLAGS = /Ze /Zx /Go /Tx86-coff /D__WIN32__ ' + '-I$(INCLUDE_C_DIR)' + CRLF
         cOut += CRLF
         cOut += '$(APP_NAME) : $(OBJ_DIR)\' + aPrgFiles[1] + '.obj'
         For i := 2 To nPrgFiles
            cOut += ' \' + CRLF
            cOut += '   $(OBJ_DIR)\' + aPrgFiles[i] + '.obj'
         Next i
         cOut += CRLF
         For i := 1 to Len( aRcFiles )
            cOut += '   $(BRC_EXE) /fo' + aRcFiles[i] + '.res ' + aRcFiles[i] + '.rc' + CRLF
         Next i
         For i := 1 To nPrgFiles
            cOut += '   echo $(OBJ_DIR)\' + aPrgFiles[i] + '.obj + >' + If( i > 1, '>', '' ) + 'b32.bc' + CRLF
         Next i
         cOut += '   echo /OUT:$(APP_NAME) >> b32.bc' + CRLF
         cOut += '   echo /FORCE:MULTIPLE >> b32.bc' + CRLF
         cOut += '   echo /LIBPATH:$(CC_LIB_DIR) >> b32.bc' + CRLF
         cOut += '   echo /LIBPATH:$(CC_LIB_DIR)\WIN >> b32.bc' + CRLF
         If File( cMiniGuiFolder + 'LIB\HB\PCC\oohg.lib' )
           cOut += '   echo ' + cMiniGuiFolder  + 'LIB\HB\BCC\oohg.lib >> b32.bc' + CRLF
         Else
           cOut += '   echo ' + cMiniGuiFolder  + 'LIB\oohg.lib >> b32.bc' + CRLF
         EndIf
         If File( cMiniGuiFolder + 'LIB\HB\PCC\hbprinter.lib' )
           cOut += '   echo ' + cMiniGuiFolder  + 'LIB\HB\BCC\hbprinter.lib >> b32.bc' + CRLF
         Else
           cOut += '   echo ' + cMiniGuiFolder  + 'LIB\hbprinter.lib >> b32.bc' + CRLF
         EndIf
         If File( cMiniGuiFolder + 'LIB\HB\PCC\miniprint.lib' )
           cOut += '   echo ' + cMiniGuiFolder  + 'LIB\HB\BCC\miniprint.lib >> b32.bc' + CRLF
         Else
           cOut += '   echo ' + cMiniGuiFolder  + 'LIB\miniprint.lib >> b32.bc' + CRLF
         EndIf
         If nOption == 2
            cOut += '   echo $(HRB_LIB_DIR)\gtwin.lib >> b32.bc' + CRLF
         EndIf
         cOut += '   echo $(HRB_LIB_DIR)\gtgui.lib >> b32.bc' + CRLF
         For Each i In { "ace32.lib", ;
                         "codepage.lib", ;
                         "common.lib", ;
                         "ct.lib", ;
                         "dbfcdx.lib", ;
                         "dbfdbt.lib", ;
                         "dbffpt.lib", ;
                         "dbfntx.lib", ;
                         "debug.lib", ;
                         "dll.lib", ;
                         "hbcommon.lib", ;
                         "hbcpage.lib", ;
                         "hbct.lib", ;
                         "hbdebug.lib", ;
                         "hbhsx.lib", ;
                         "hblang.lib", ;
                         "hbmacro.lib", ;
                         "hbmisc.lib", ;
                         "hbmzip.lib", ;
                         "hbodbc.lib", ;
                         "hboleaut.lib", ;
                         "hbpcre.lib", ;
                         "hbpp.lib", ;
                         "hbrdd.lib", ;
                         "hbrtl.lib", ;
                         "hbsix.lib", ;
                         "hbtip.lib", ;
                         "hbvm.lib", ;
                         "hbwin.lib", ;
                         "hbzlib.lib", ;
                         "hsx.lib", ;
                         "lang.lib", ;
                         "libmisc.lib", ;
                         "libmysqldll.lib", ;
                         "macro.lib", ;
                         "minizip.lib", ;
                         "mysql.lib", ;
                         "odbc32.lib", ;
                         "pcrepos.lib", ;
                         "pp.lib", ;
                         "rdd.lib", ;
                         "rddads.lib", ;
                         "rddcdx.lib", ;
                         "rddfpt.lib", ;
                         "rddntx.lib", ;
                         "rtl.lib", ;
                         "tip.lib", ;
                         "vm.lib", ;
                         "xhb.lib", ;
                         "ziparchive.lib", ;
                         "zlib1.lib" }
            If File( cHarbourFolder + 'LIB\' + i )
               cOut += '   echo $(HRB_LIB_DIR)\' + i + ' >> b32.bc' + CRLF
            EndIf
         Next
         cOut += '   echo $(CC_LIB_DIR)\crt.lib >> b32.bc' + CRLF
         For Each i In { "kernel32.lib", ;
                         "winspool.lib", ;
                         "user32.lib", ;
                         "advapi32.lib", ;
                         "ole32.lib", ;
                         "uuid.lib", ;
                         "oleaut32.lib", ;
                         "mpr.lib", ;
                         "comdlg32.lib", ;
                         "comctl32.lib", ;
                         "gdi32.lib", ;
                         "olepro32.lib", ;
                         "shell32.lib", ;
                         "winmm.lib", ;
                         "vfw32.lib", ;
                         "wsock32.lib" }
            If File( cHarbourFolder + 'LIB\' + i )
               cOut += '   echo ' + i + ' >> b32.bc' + CRLF
            EndIf
         Next
         For i := 1 to Len( aRcFiles )
            cOut += '   echo ' + aRcFiles[i] + '.res >> b32.bc' + CRLF
         Next i
         cOut += '   echo ' + cMiniGUIFolder + 'resources\oohg.res >> b32.bc' + CRLF
         cOut += '   $(ILINK_EXE)  /SUBSYSTEM:' + If( nOption == 2, "CONSOLE", "WINDOWS" ) + ' @b32.bc' + CRLF
         cOut += CRLF
         For i := 1 To nPrgFiles
            cOut += CRLF
            cOut += '$(C_DIR)\' + aPrgFiles[i] + '.c : ' + cProjFolder + aPrgFiles[i] + '.prg' + CRLF
            cOut += '   $(HARBOUR_EXE) $(HARBOUR_FLAGS) $** -o$@'  + CRLF
            cOut += CRLF
            cOut += '$(OBJ_DIR)\' + aPrgFiles[i] + '.obj : $(C_DIR)\' + aPrgFiles[i] + '.c' + CRLF
            cOut += '   $(CC) $(COBJFLAGS) -Fo$@ $**' + CRLF
         Next i
         MemoWrit( '_temp.bc', cOut )    

         // Build batch
         cOut := ''
         cOut += '@echo off' + CRLF
         cOut += cCompFolder + 'BIN\POMAKE.EXE /F' + cProjFolder + '_temp.bc > ' + cProjFolder + 'error.lst' + CRLF
         MemoWrit( '_build.bat', cOut )

         // Create folder for objects
         CreateFolder( cProjFolder + 'OBJ' )

         // Build
         EXECUTE FILE '_build.bat' WAIT HIDE

   CASE ::ltbuild==1 // Compile.bat

         // Check for compile file
         If ! File( 'compile.bat' ) .and. ! IsFileInPath( 'compile.bat' )
            waitmess:Hide()
            MsgInfo( 'Copy file COMPILE.BAT from ooHG root folder to the current' + CRLF + 'project folder, or add ooHG root folder to PATH.', 'ooHG IDE+' )
            Break
         EndIf

         // Build auxiliary source file
         nItems := Form_Tree:Tree_1:ItemCount
         aPrgFiles := {}
         For i := 1 To nItems
            cFile := Form_Tree:Tree_1:Item( i )
            If ::SearchTypeAdd( ::SearchItem( cFile, 'Prg module' ) ) == 'Prg module' .and. cFile <> 'Prg module'
               cFile := Upper( AllTrim( cFile + '.PRG' ) )
               If aScan( aPrgFiles, cFile ) == 0
                  aAdd( aPrgFiles, cFile )
               EndIf
            EndIf
         Next i
         nPrgFiles := Len( aPrgFiles )
         If nPrgFiles == 0
            waitmess:Hide()
            MsgStop( 'Project has no .PRG files.', 'ooHG IDE+' )
            Break
         EndIf
         cOut := ''
         For i := 1 To nPrgFiles
            cOut += "# include '" + aPrgFiles[i] + "'" + CRLF + CRLF
         Next i
         MemoWrit( cPrgName + '.prg', cOut )

         // Compile and link
         cDosComm := '/c compile ' + cPrgName + ' /nr /l' + If( nOption == 2, " /d", "" )
         EXECUTE FILE 'CMD.EXE' PARAMETERS cDosComm HIDE

      EndCase

      // Check for errors
      cError := MemoRead( 'error.lst' )
      cError1 := Upper( cError )
      If At( 'ERROR', cError1 ) > 0 .or. At( 'FATAL', cError1 ) > 0 .or. At( 'LD RETURNED 1 EXIT STATUS', cError1 ) > 0
         waitmess:Hide()
         ::ViewErrors( cError )
         Break
      ElseIf ! File( cExe )
         waitmess:Hide()
         MsgStop( 'EXE is missing.', 'ooHG IDE+' )
         Break
      EndIf

      // Rename or move
      If ! Empty( ::cOutFile )
         cOut := Upper( AllTrim( ::cOutFile ) )
         If Right( cOut, 4 ) != ".EXE"
            cOut += ".EXE"
         EndIf
         cDosComm := '/c move ' + cExe + ' ' + cOut
         EXECUTE FILE 'CMD.EXE' PARAMETERS cDosComm HIDE
         If ! File( cOut )
            waitmess:Hide()
            MsgStop( "Can't move or rename EXE file.", 'ooHG IDE+' )
            Break
         EndIf
         cExe := cOut
      EndIf

      // Cleanup
      BorraTemp( cProjFolder )
      waitmess:Hide()
      If nOption == 0
         MsgInfo( 'Project builded.', 'ooHG IDE+' )
      ElseIf nOption == 1 .or. nOption == 2
         EXECUTE FILE cExe
      EndIf
   End Sequence

   CursorArrow()
   Form_Tree:button_9:Enabled := .T.
   Form_Tree:button_10:Enabled := .T.
   Form_Tree:button_11:Enabled := .T.
Return

//------------------------------------------------------------------------------
METHOD ViewErrors( wr ) CLASS THMI
//------------------------------------------------------------------------------
   Local Form_Errors, oEdit, oButt

   If HB_IsString( wr )
      DEFINE WINDOW Form_Errors OBJ Form_Errors ;
         AT 10, 10 ;
         CLIENTAREA WIDTH 650 HEIGHT 480 ;
         TITLE 'Error Report' ;
         ICON 'Edit' ;
         MODAL ;
         FONT "Times new Roman" ;
         SIZE 10 ;
         BACKCOLOR ::asystemcolor ;
         ON INIT ( oButt:Col := Form_Errors:ClientWidth - 40, ;
                   oEdit:Width := Form_Errors:ClientWidth - 45, ;
                   oEdit:Height := Form_Errors:ClientHeight ) ;
         ON SIZE ( oButt:Col := Form_Errors:ClientWidth - 40, ;
                   oEdit:Width := Form_Errors:ClientWidth - 45, ;
                   oEdit:Height := Form_Errors:ClientHeight ) ;

         @ 0, 0 EDITBOX Edit_1 ;
            OBJ oEdit ;
            WIDTH 590 ;
            HEIGHT 445 ;
            VALUE wr ;
            READONLY ;
            FONT 'FixedSys' ;
            SIZE 10 ;
            BACKCOLOR {255, 255, 235}

         @ 10, 595 Button Butt_1 ;
            OBJ oButt ;
            CAPTION 'Exit' ;
            ACTION Form_Errors:Release() ;
            WIDTH 35 ;
            FLAT
      END WINDOW

      CENTER WINDOW Form_Errors
      ACTIVATE WINDOW Form_Errors
   EndIf
Return Nil

*-------------------------
METHOD ViewSource( wr ) CLASS THMI
*-------------------------
if !HB_IsString( wr )
   return nil
ENdif
DEFINE WINDOW c_source obj c_source  ;
   AT 10,10 ;
   WIDTH 625 HEIGHT 460 ;
   TITLE 'Source code' ;
   ICON 'Edit' ;
   MODAL ;
   FONT "Times new Roman" ;
   SIZE 10 ;
   backcolor  ::asystemcolor

   @ 0,0 EDITBOX EDIT_1 ;
   WIDTH 573 ;
   HEIGHT 425 ;
   VALUE WR ;
   READONLY ;
   FONT 'FixedSys' ;
   SIZE 10 ;
   backcolor {255,255,235}

   @ 10,575 Button _exiterr ;
   caption 'Exit' ;
   action {|| c_source:release() } ;
   width 35 FLAT

   @ 50,575 Button _prints ;
   caption 'Print' ;
   action {|| printitem(wr) } ;
   width 35 FLAT

END WINDOW
CENTER WINDOW c_source
ACTIVATE WINDOW c_source
return

*-------------------------
METHOD Newproject() CLASS THMI
*-------------------------
if .not. ::lPsave
   If MsgYesNo( 'Current project not saved, save it now?', 'ooHG IDE+' )
      ::saveproject()
   endif
endif

Form_Tree:Tree_1:deleteAllitems()
Form_Tree:Tree_1:AddItem( 'Project'   , 0 )
Form_Tree:Tree_1:AddItem( 'Form module' , 1 )
Form_Tree:Tree_1:AddItem( 'Prg module' , 1 )
Form_Tree:Tree_1:AddItem( 'CH module' , 1 )
Form_Tree:Tree_1:AddItem( 'Rpt module' , 1 )
Form_Tree:Tree_1:AddItem( 'RC module' , 1 )
Form_Tree:Tree_1:value := 1
Form_Tree:title := cNameApp
::lPsave:=.F.
::cprojectname:=''
   Desactiva(0)           // MigSoft
return


*-------------------------
METHOD Openproject() CLASS THMI
*-------------------------
cos=upper(gete('os'))
if len(cos)=0
   cos=gete('os_type')
endif
******
if file(exedir)
   cvccvar:=alltrim(memoread(exedir))
   dirchange(cvccvar)
endif
*****
   ::cFile := GetFile ( { {'ooHG IDE+ project files *.pmg','*.pmg'} }  , 'Open Project',cvccvar,.F.,.F. )

If len(::cFile)=0
   return
Else                                          // MigSoft
   pmgFolder := OnlyFolder( ::cFile )     // MigSoft
   Desactiva(1)                               // MigSoft
endif
openauxi( Self )
return Nil

************
*-------------------------------------------
Function openauxi( myIde, cvar )
*-------------------------------------------
local Aline [0]
local nContlin,nPosilin,nFinform,nValue
local cproject, chmi
nContlin:=0
nPosilin:=1
if cvar#NIL
   myIde:cfile:=cvar+".pmg"
   pmgFolder := OnlyFolder( myIde:cFile )     // MigSoft
   dirchange(pmgFolder)
   rtl:=NIL
endif
chmi := "hmi.INI"
IF .not. file(chmi)
   a := MemoWrit( chmi, '[PROJECT]' )
else

ENDIF
BEGIN INI FILE (chmi)

   GET myIde:cProjFolder     SECTION 'PROJECT'  ENTRY "PROJFOLDER"    default ''   // MigSoft
   GET myIde:cOutFile        SECTION 'PROJECT'  ENTRY "OUTFILE"       default ''

   GET myIde:cExteditor      SECTION "EDITOR"   ENTRY "external"      default ''

   GET myIde:cGuiHbMinGW     SECTION 'GUILIB'   ENTRY "GUIHBMINGW"    default 'c:\oohg'
   GET myIde:cGuiHbBCC       SECTION 'GUILIB'   ENTRY "GUIHBBCC"      default 'c:\oohg'
   GET myIde:cGuiHbPelles    SECTION 'GUILIB'   ENTRY "GUIHBPELL"     default 'c:\oohg'
   GET myIde:cGuixHbMinGW    SECTION 'GUILIB'   ENTRY "GUIXHBMINGW"   default 'c:\oohg'
   GET myIde:cGuixHbBCC      SECTION 'GUILIB'   ENTRY "GUIXHBBCC"     default 'c:\oohg'
   GET myIde:cGuixHbPelles   SECTION 'GUILIB'   ENTRY "GUIXHBPELL"    default 'c:\oohg'

   GET myIde:cHbMinGWFolder  SECTION 'HARBOUR'  ENTRY "HBMINGW"       default 'c:\oohg\harbour'
   GET myIde:cHbBCCFolder    SECTION 'HARBOUR'  ENTRY "HBBCC"         default 'c:\harbourb'
   GET myIde:cHbPellFolder   SECTION 'HARBOUR'  ENTRY "HBPELLES"      default 'c:\harbourp'

   GET myIde:cxHbMinGWFolder SECTION 'HARBOUR'  ENTRY "XHBMINGW"      default 'c:\xharbourm'
   GET myIde:cxHbBCCFolder   SECTION 'HARBOUR'  ENTRY "XHBBCC"        default 'c:\xharbourb'
   GET myIde:cxHbPellFolder  SECTION 'HARBOUR'  ENTRY "XHBPELLES"     default 'c:\xharbourp'

   GET myIde:cMinGWFolder    SECTION 'COMPILER' ENTRY "MINGWFOLDER"   default 'c:\oohg\MinGW'
   GET myIde:cBCCFolder      SECTION 'COMPILER' ENTRY "BCCFOLDER"     default 'c:\oohg\BCC55'
   GET myIde:cPellFolder     SECTION 'COMPILER' ENTRY "PELLESFOLDER"  default 'c:\oohg\PellesC'

   GET myIde:nCompxBase      SECTION 'WHATCOMP' ENTRY "XBASECOMP"     default 1
   GET myIde:nCompilerC      SECTION 'WHATCOMP' ENTRY "CCOMPILER"     default 1

   GET myIde:ltbuild         SECTION 'SETTINGS' ENTRY "BUILD"         default 2
   GET myIde:lsnap           SECTION 'SETTINGS' ENTRY "SNAP"          default 0
   GET myIde:clib            SECTION 'SETTINGS' ENTRY "LIB"           default ''

END INI

************
myIde:cprojectname:=myIde:cFile
cproject:=memoread(myIde:cFile)
Form_Tree:title := cNameApp+' ('+myIde:cfile+')'
Form_Tree:Tree_1:deleteAllitems()
ncontlin:=mlcount(cproject)
Form_Tree:Tree_1:AddItem( 'Project'   , 0 )
Form_Tree:Tree_1:AddItem( 'Form module' , 1 )
Form_Tree:Tree_1:AddItem( 'Prg module' , 1 )
Form_Tree:Tree_1:AddItem( 'CH module' , 1 )
Form_Tree:Tree_1:AddItem( 'Rpt module' , 1 )
Form_Tree:Tree_1:AddItem( 'RC module' , 1 )
sw:=0
For i:=1 to ncontlin
    aAdd(Aline,trim(memoline(cproject,,i)))
    aline[i]:=strtran(aline[i],chr(10),"")
    aline[i]:=strtran(aline[i],chr(13),"")
    aline[i]:=trim(aline[i])
    do case
       case Aline[i] =='Project'
       case Aline[i]=='Form module'
          sw:=1
       case  Aline[i]=='Prg module'
          sw:=2
       case Aline[i]=='CH module'
          sw:=3
       case Aline[i]=='Rpt module'
          sw:=4
       case Aline[i]=='RC module'
          sw:=5
       otherwise
          if sw==1
             myIde:newformfromar(Aline[i])
          endif
          if sw==2
             myIde:newprgfromar(Aline[i])
          endif
          if sw==3
             myIde:newchfromar(Aline[i])
          endif
          if sw==4
             myIde:newrptfromar(Aline[i])
          endif
          if sw==5
             myIde:newrcfromar(Aline[i])
          endif
    endcase
Next i
Form_Tree:Tree_1:value := 1
Form_Tree:tree_1:Expand ( 1 )
return

//------------------------------------------------------------------------------
METHOD SaveProject() CLASS THMI
//------------------------------------------------------------------------------
   Local Output
   Local nIitems
   Local i

   Output := ''
   nItems := Form_Tree:Tree_1:ItemCount
   For i := 1 To nItems
      cItem := Form_Tree:Tree_1:Item( i )
      Output += cItem + CRLF
   Next i
   Output += ''

   If Empty( ::cProjectName )
      ::cProjectName := PutFile( { { 'ooHG IDE+ project files *.pmg', '*.pmg' } }, 'ooHG IDE+ - Save Project' )
      If Upper( Right( ::cProjectName, 4 ) ) != '.PMG'
         ::cProjectName += '.pmg'
      EndIf
      If Upper( ::cProjectName ) == '.PMG'
         ::cProjectName := ''
      EndIf
   EndIf

   pmgFolder := OnlyFolder( ::cProjectName )
   Form_Tree:Title := cNameApp + ' (' + ::cProjectName + ')'
   If ! Empty( ::cProjectName)
      Desactiva( 1 )
   Endif

   If Empty( ::cProjectName )
      MsgStop( 'Project not saved.', 'ooHG IDE+' )
   Else
      MemoWrit( ::cProjectName, Output )
      ::lPsave := .T.
      MsgInfo( 'Project saved.', 'ooHG IDE+' )
   EndIf
Return


*-------------------------
METHOD newform() CLASS THMI
*-------------------------
local cPform
cPform:=inputbox('Form module','Add Form module')
if val(cPform)>0
   MsgStop( 'The name must begin with a letter.', 'ooHG IDE+' )
   return
endif
if at('.',cPform)#0
   MsgStop( 'The name must not contain a dot (.) in it.', 'ooHG IDE+' )
   return
endif

if len(cPform)>0
   if ::searchitem(cPform,'Form module')>0 .and. ::searchtypeadd(::searchitem(cPform,'Form module'))=='Form module'
      MsgStop( 'This name is not allowed.', 'ooHG IDE+' )
      return
   endif
   Form_Tree:Tree_1:AddItem( cPform , 2 )
   ::lPsave:=.F.
endif
Return


*-------------------------
METHOD newformfromar(cPform) CLASS THMI
*-------------------------
if len(cPform)>0
   if ::searchitem(cPform,'Form module')>0 .and. ::searchtypeadd(::searchitem(cPform,'Form module'))=='Form module'
      MsgStop( 'This name is not allowed.', 'ooHG IDE+' )
      return
   endif
   Form_Tree:Tree_1:AddItem( cPform , 2 )
endif
Return


*-------------------------
METHOD Newprgfromar(cPprg) CLASS THMI
*-------------------------
local nValue
if len(cPprg)>0
   if ::searchitem(cPprg,"Prg module")>0 .and. ::searchtypeadd(::searchitem(cPprg,"Prg module"))=='Prg module'
      MsgStop( 'This name is not allowed.', 'ooHG IDE+' )
      return
   endif
   nValue:=::searchitem('Prg module',"Prg module")
   Form_Tree:Tree_1:AddItem( cPprg , nValue)
endif
Return


*-------------------------
METHOD Newchfromar(cPch) CLASS THMI
*-------------------------
local nValue
if len(cPch)>0
   if ::searchitem(cPch,"CH module")>0 .and. ::searchtypeadd(::searchitem(Cpch,"CH module"))=='CH module'
      MsgStop( 'This name is not allowed.', 'ooHG IDE+' )
      return
   endif
   nValue:=::searchitem('CH module',"CH module")
   Form_Tree:Tree_1:AddItem( cPch , nValue)
endif
Return


*-------------------------
METHOD Newrcfromar(cPrc) CLASS THMI
*-------------------------
local nValue
if len(cPrc)>0
   if ::searchitem(cPrc,"RC module")>0 .and. ::searchtypeadd(::searchitem(Cprc,"RC module"))=='RC module'
      MsgStop( 'This name is not allowed.', 'ooHG IDE+' )
      return
   endif
   nValue:=::searchitem('RC module',"RC module")
   Form_Tree:Tree_1:AddItem( cPrc , nValue)
endif
Return


*-------------------------
METHOD Newrptfromar(cPrpt) CLASS THMI
*-------------------------
local nValue
if len(cPrpt)>0
   if ::searchitem(cPrpt,"Rpt module")>0 .and. ::searchtypeadd(::searchitem(Cprpt,"Rpt module"))=='Rpt module'
      MsgStop( 'This name is not allowed.', 'ooHG IDE+' )
      return
   endif
   nValue:=::searchitem('Rpt module',"Rpt module")
   Form_Tree:Tree_1:AddItem( cPrpt , nValue)
endif
Return



*-------------------------
METHOD Newprg() CLASS THMI
*-------------------------
local cPprg,nValue
nvalue:=0
cPprg:=inputbox('Prg Module','Add Prg Module')
if val(cPprg)>0
   MsgStop( 'The name must begin with a letter.', 'ooHG IDE+' )
   return
endif
if at('.',cPprg)#0
   MsgStop( 'The name must not contain a dot (.) in it.', 'ooHG IDE+' )
   return
endif
if len(cPprg)>0
   if ::searchitem(cPprg,'Prg module')>0 .and. ::searchtypeadd(::searchitem(cPprg,'Prg module'))=='Prg module'
      MsgStop( 'This name is not allowed.', 'ooHG IDE+' )
      return
   endif
   nValue:=::searchitem('Prg module','Prg module')
   Form_Tree:Tree_1:AddItem( cPprg , nValue)
   ::lPsave:=.F.
endif
Return


*-------------------------
METHOD Newch() CLASS THMI
*-------------------------
local cPch,nValue
cPch:=inputbox('CH Module','Add CH Module')
if val(cPch)>0
   MsgStop( 'The name must begin with a letter.', 'ooHG IDE+' )
   return
endif
if at('.',cPch)#0
   MsgStop( 'The name must not contain a dot (.) in it.', 'ooHG IDE+' )
   return
endif
if len(cPch)>0
   if ::searchitem(cPch,'CH module')>0 .and. ::searchtypeadd(::searchitem(Cpch,'CH module'))=='CH module'
      MsgStop( 'This name is not allowed.', 'ooHG IDE+' )
      return
   endif
   nValue:=::searchitem('CH module','CH module')
   Form_Tree:Tree_1:AddItem( cPch , nValue)
   ::lPsave:=.F.
endif
Return


*-------------------------
METHOD Newrc() CLASS THMI
*-------------------------
local cPrc,nValue
cPrc:=inputbox('RC Module','Add RC Module')
if val(cPrc)>0
   MsgStop( 'The name must begin with a letter.', 'ooHG IDE+' )
   return
endif
if at('.',cPrc)#0
   MsgStop( 'The name must not contain a dot (.) in it.', 'ooHG IDE+' )
   return
endif
if len(cPrc)>0
   if ::searchitem(cPrc,'RC module')>0 .and. ::searchtypeadd(::searchitem(Cprc,'RC module'))=='RC module'
      MsgStop( 'This name is not allowed.', 'ooHG IDE+' )
      return
   endif
   nValue:=::searchitem('RC module','RC module')
   Form_Tree:Tree_1:AddItem( cPrc , nValue)
   ::lPsave:=.F.
endif
Return


*-------------------------
METHOD Newrpt() CLASS THMI
*-------------------------
local cPrpt,nValue
cPrpt:=inputbox('Rpt Module','Add Rpt Module')
if val(cPrpt)>0
   MsgStop( 'The name must begin with a letter.', 'ooHG IDE+' )
   return
endif
if at('.',cPrpt)#0
   MsgStop( 'The name must not contain a dot (.) in it.', 'ooHG IDE+' )
   return
endif
if len(cPrpt)>0
   if ::searchitem(cPrpt,'Rpt module')>0 .and. ::searchtypeadd(::searchitem(Cprpt,'Rpt module'))=='Rpt module'
      MsgStop( 'This name is not allowed.', 'ooHG IDE+' )
      return
   endif
   nValue:=::searchitem('Rpt module','Rpt module')
   Form_Tree:Tree_1:AddItem( cPrpt , nValue)
   ::lPsave:=.F.
endif
Return


*-------------------------
METHOD deleteitemp() CLASS THMI
*-------------------------
local cItem,cparent
cItem:=Form_Tree:Tree_1:item(Form_Tree:Tree_1:Value)
if cItem == 'Form module' .or. cItem=='Prg module' .or. cItem == 'Project' .or. cItem=='CH module' .or. cItem=='Rpt module' .or. cItem=='RC module'
   MsgStop( "This item can't be deleted.", 'ooHG IDE+' )
   return
endif

   If MsgYesNo( 'Item ' + cItem + ' will be removed, are you sure?', 'ooHG IDE+' )
   Form_Tree:Tree_1:DeleteItem( Form_Tree:Tree_1:Value )
   ::lPsave:=.F.
endif
return

*-------------------------
METHOD searchitem(cnameitem,cparent) CLASS THMI
*-------------------------
local nitems,i,cItem,sw
sw:=0
nItems:=Form_Tree:Tree_1:ItemCount
for i:=1 to nItems
    cItem:=Form_Tree:Tree_1:Item ( i )
    if cItem==cparent
       sw:=1
    endif
    if sw=1
       if upper(cItem) == upper(cnameitem)
          return i
       endif
    endif
next i
return 0


*-------------------------
METHOD searchtypeadd(nvalue) CLASS THMI
*-------------------------
local l
IF !HB_IsNumeric( nvalue)
   Return NIL
ENDIF
For l:= nValue to 1 step -1
    if Form_Tree:Tree_1:item(l) == 'Form module'
       return ('Form module')
    endif
    if Form_Tree:Tree_1:item(l) == 'Prg module'
       return ('Prg module')
    endif
    if Form_Tree:Tree_1:item(l) == 'CH module'
       return ('CH module')
    endif
    if Form_Tree:Tree_1:item(l) == 'Rpt module'
       return ('Rpt module')
    endif
    if Form_Tree:Tree_1:item(l) == 'RC module'
       return ('RC module')
    endif
Next l
return nil


*-------------------------
METHOD searchtype() CLASS THMI
*-------------------------
local i
nValue:= Form_Tree:Tree_1:Value
For i:= nValue to 1 step -1
    if Form_Tree:Tree_1:item(i) == 'Form module'
       return ('Form module')
    endif
    if Form_Tree:Tree_1:item(i) == 'Prg module'
       return ('Prg module')
    endif
    if Form_Tree:Tree_1:item(i) == 'CH module'
       return ('CH module')
    endif
    if Form_Tree:Tree_1:item(i) == 'Rpt module'
       return ('Rpt module')
    endif
    if Form_Tree:Tree_1:item(i) == 'RC module'
       return ('RC module')
    endif
Next i
return nil


*-------------------------
METHOD modifyitem(cItem,cparent) CLASS THMI
*-------------------------
if citem=NIL
   cItem:=Form_Tree:Tree_1:item(Form_Tree:Tree_1:Value)
   cParent= ::searchtype(::searchitem(cItem,'Form module'))
endif

if cParent == 'Prg module'                                    // MigSoft
   if file(citem+'.prg')
      ::Openfile(cItem+'.prg')
      ::alinet:={}
   else
      output:='/*        IDE: ooHG IDE+'+CRLF
      output+=' *     Project: '+::cprojectname+CRLF
      output+=' *        Item: '+cItem+'.prg'+CRLF
      output+=' * Description: '+CRLF
      output+=' *      Author: '+CRLF
      output+=' *        Date: '+dtoc(date())+CRLF
      output+=' */'+CRLF+CRLF

      output+="#include 'oohg.ch'"+CRLF                           // MigSoft
      output+=+CRLF
      output+="*------------------------------------------------------*"+CRLF
      if ::searchitem(cItem,cParent)= (::searchitem(cParent,cParent)+1)
         output += 'Function Main()'+CRLF
      else
         output += 'Function '+cItem+'()'+CRLF                    // MigSoft
      endif
      output+="*------------------------------------------------------*"+CRLF+CRLF
      output += 'Return Nil'+CRLF+CRLF
      MemoWrit( cItem + '.prg', output )
      ::Openfile(cItem+'.prg')
      ::alinet:={}
   endif
endif
if cParent == 'CH module'
   if file(citem+'.ch')
      ::Openfile(cItem+'.ch')
      ::alinet:={}
   else
      output:='/*        IDE: ooHG IDE+'+CRLF
      output+=' *     Project: '+::cprojectname+CRLF
      output+=' *        Item: '+cItem+'.ch'+CRLF
      output+=' * Description:'+CRLF
      output+=' *      Author:'+CRLF
      output+=' *        Date: '+dtoc(date())+CRLF
      output+=' */'+CRLF+CRLF
      output += '#'+CRLF
      MemoWrit( cItem + '.ch', output )
      ::Openfile(cItem+'.ch')
      ::alinet:={}
   endif
endif
if cParent == 'RC module'
   if file(citem+'.rc')
      ::Openfile(cItem+'.rc')
      ::alinet:={}
   else
      output:='//         IDE: ooHG IDE+'+CRLF
      output+='//     Project: '+::cprojectname+CRLF
      output+='//        Item: '+cItem+'.rc'+CRLF
      output+='// Description:'+CRLF
      output+='//      Author:'+CRLF
      output+='//        Date: '+dtoc(date())+CRLF
      output+='// Name    Format   Filename'+CRLF
      output+='// MYBMP   BITMAP   res\Next.bmp'+CRLF
      output+='// Last line of this file must end with a CRLF'+CRLF

      wauxi:=memoread('auxi.rc')
/////////////// ojo
      output+= wauxi
      MemoWrit( cItem + '.rc', output )
      ::Openfile(cItem+'.rc')
      ::alinet:={}
   endif
endif
return nil


*-------------------------
METHOD modifyRpt(cItem,cparent) CLASS THMI
*-------------------------
if citem=NIL
   cItem:=Form_Tree:Tree_1:item(Form_Tree:Tree_1:Value)
   cParent= ::searchtype(::searchitem(cItem,'Rpt module'))
endif

if cParent == 'Rpt module'
   Repo_Edit( Self, cItem + '.rpt' )
endif
return nil


*-------------------------
METHOD modifyform(citem,cparent) CLASS THMI
*-------------------------
local npos
if citem=NIL
   cItem:=Form_Tree:Tree_1:item(Form_Tree:Tree_1:Value)
   cParent= ::searchtype(::searchitem(cItem,'Form module'))
endif
citem:=lower(citem)
do while (npos:=at(".",cItem))>0
   cItem:=substr(cItem,1,npos-1)
enddo
if cParent == 'Form module'
   myform:=tform1()
   myform:vd( cItem + '.fmg', Self )
   close data
endif
return  nil

//------------------------------------------------------------------------------
METHOD SaveFile( cdfile ) CLASS THMI
//------------------------------------------------------------------------------
   If AllTrim( editbcvc:edit_1:Value ) == ''
      If File( cdfile )
         DELETE FILE &cdfile
      EndIf
      ::lSave := .T.
   Else
      If MemoWrit( cdfile, RTrim( editbcvc:edit_1:Value ) )
         ::lSave := .T.
      Else
         MsgStop( 'Error writing ' + cdfile + '.', 'ooHG IDE+' )
      EndIf
   EndIf
Return Nil

*-------------------------
METHOD Openfile(cdfile) CLASS THMI
*-------------------------
local nContlin,nPosilin,nFinform,nValue,coutput,nwidth,nheight
local cprg,wq,nrat
::lsave:=.T.
::npostext:=0
::ctext:=''
::ntemp:=0
cursorwait()
waitmess:show()
waitmess.hmi_label_101.value:='Loading File....'
IF len(alltrim(::cExteditor))=0
   cTextedit:=memoread(cdFile)
   cTextedit:=strtran(cTextedit,chr(9),space(8))  &&& replace tabs with space(8)
   coutput:=''
   for i:=1 to mlcount(ctextedit)
       coutput:=coutput+rtrim(memoline(cTextedit,500,i))+CRLF  &&& rtrim of each line
   next i
   cTextedit:=rtrim(coutput)
   ***   patras:=rat
   do while .t.
      wq:=substr(coutput,len(cTextedit)-1,1)
      if wq=chr(13) .or. wq=chr(10)
         cTextedit:=left(cTextedit,len(ctextedit)-1)
      else
         cTextedit:=left(cTextedit,len(ctextedit)-1)+CRLF
         exit
      endif
   enddo

   if iswindowdefined(editbcvc)
      waitmess:hide()
      MsgStop( 'Can only edit one form at a time.', 'ooHG IDE+' )
      return nil
   endif

   nwidth:=getformobject("Form_Tree"):width - (getformobject("Form_Tree"):width/3.5)
   nheight:=getformobject("Form_Tree"):height-160

          // Migsoft , cvc modified
   DEFINE WINDOW editbcvc obj editbcvc AT 109,80 WIDTH nWidth  HEIGHT nHeight TITLE cNameApp+" "+cdfile ICON 'EDIT' CHILD FONT "Courier New" SIZE 10 backcolor ::asystemcolor ON SIZE AjustaEditor()

      @ 30,2 RICHEDITBOX edit_1 WIDTH editbcvc:width-15 HEIGHT editbcvc:height-90 VALUE cTextedit ;
             BACKCOLOR {255,255,235} MAXLENGTH 256000 ON CHANGE {|| ::lsave:=.F.  } ;
             ON GOTFOCUS {|| ::posxy() }                  // MigSoft

      if len(editbcvc:edit_1:value)>100000
         MsgInfo( 'You should use another program editor', 'ooHG IDE+' )
      endif

      if len(editbcvc:edit_1:value)>250000
         MsgStop('You must use another program editor', 'ooHG IDE+' )
         return nil
      endif

      ll:=mlcount(editbcvc:edit_1:value)
      if ll<=800
         ninterval:=1000
      else
         ninterval:=int((((ll-800)/800)+1)*2000)
      endif

      DEFINE TIMER Timit INTERVAL ninterval ACTION ::lookchanges()

      DEFINE SPLITBOX

      DEFINE TOOLBAR ToolBar_1x BUTTONSIZE 20,20 FLAT FONT 'Calibri' SIZE 9   // MigSoft

         BUTTON button_2 tooltip 'Exit(Esc)'    picture 'Exit'  ACTION ::saveandexit(cdfile)
         BUTTON button_1 tooltip 'Save(F2)'     Picture 'Save'  ACTION ::savefile(cdfile)
         BUTTON button_3 tooltip 'Find(Ctrl-F)' picture 'M10'   ACTION ::txtsearch()
         BUTTON button_4 tooltip 'Next(F3)'     picture 'Next'  ACTION ::nextsearch()
         BUTTON button_5 tooltip 'Go(Ctrl-G)'   picture 'Go'    ACTION ::goline()
         nrat:=rat('.prg',cdfile)
         if nrat>0
            BUTTON button_6 tooltip 'Reformat(Ctrl-R)' picture 'tbarb'  ACTION reforma1(editbcvc:edit_1:value)
         endif
      END TOOLBAR

      END SPLITBOX

      on key F2 of editbcvc action ::savefile(cdfile)
      on key F3 of editbcvc action ::nextsearch()
      on key CTRL+F of editbcvc action ::txtsearch()
      on key CTRL+G of editbcvc action ::goline()
      on key ESCAPE of editbcvc action ::saveandexit(cdfile)
      if nrat>0
            on key CTRL+R of editbcvc action reforma1(editbcvc:edit_1:value)
      endif

      DEFINE STATUSBAR
         STATUSITEM " Lin:     Col:     Caret:     " WIDTH 20
         KEYBOARD
         DATE WIDTH 100
         CLOCK WIDTH 90
      END STATUSBAR

      DEFINE CONTEXT MENU

         MENUITEM 'Cut' ACTION send_CUT()
         MENUITEM 'Copy' ACTION send_COPY()
         MENUITEM 'Paste' ACTION send_paste()
         MENUITEM 'Delete' action  _PushKey ( 32 )
         SEPARATOR
         MENUITEM 'Select all' ACTION send_selectall()

      END MENU

   END WINDOW

   center window editbcvc
   waitmess:hide()
   cursorarrow()
   ACTIVATE WINDOW editbcvc
ELSE
   cRun:=::cExteditor+' '+cdfile

   waitmess:hide()
   cursorarrow()
   EXECUTE FILE cRun WAIT

ENDIF
return nil

static Function pulsatecla()
return nil

*---------------------------------------*
Procedure AjustaEditor()
*---------------------------------------*
   editbcvc.Edit_1.width  := editbcvc:width-15
   editbcvc.Edit_1.height := editbcvc:height-90

Return

*-------------------------
Function reforma1(ccontenido)
*-------------------------
waitmess:hmi_label_101:value:='Reformating ....'
waitmess:show()
coutput:=reforma(ccontenido)
editbcvc:edit_1:value:=coutput
waitmess:hide()
editbcvc:edit_1:setfocus()
return nil

*-------------------------
Function reforma(ccontenido)
*-------------------------
local ntab:=0
local lcero:=0
local coutput:=''
local swclase:=0
local cantlin:=''
local swcase:=0
local swc:=0
local i,clineaorig,clinea,cllinea,cdeslin
local largo
ccontenido:=strtran(ccontenido,chr(9),space(8))
largo:=mlcount(ccontenido)
for i=1 to largo
    if i>0
       cantlin:=ltrim(rtrim(memoline(ccontenido,500,i-1)))
    endif
    if i< largo
       cdeslin:=ltrim(rtrim(memoline(ccontenido,500,i+1)))
    endif
    clineaorig:=memoline(ccontenido,500,i)
    clinea1:=rtrim(clineaorig)
    clinea:=ltrim(rtrim(clineaorig))
    cllinea:=upper(clinea)
    do case
       case substr(cllinea,1,4)='CASE' .or. substr(cllinea,1,9)='OTHERWISE'
          if swcase=0
             coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
             ntab:=ntab+3
             swcase:=-1
          else
             if swcase=-1
                ntab:=ntab-3
                coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
                swcase:=1
                ntab:=ntab+3
             else
                ntab:=ntab-3
                coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
                swcase=-1
                ntab:=ntab+3
             endif
          endif

       case substr(cllinea,1,9)='DO WHILE '
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3

       case substr(cllinea,1,17)='#PRAGMA BEGINDUMP'
          coutput:=coutput+replicate(' ',ntab)+clineaorig+CRLF
          swc:=1
       case substr(cllinea,1,15)='#PRAGMA ENDDUMP'
          coutput:=coutput+replicate(' ',ntab)+clineaorig+CRLF
          swc:=0
       case substr(cllinea,1,9)='BEGIN INI'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3

       case substr(cllinea,1,7)='END INI'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF

       case substr(cllinea,1,9)='FUNCTION '
          if substr(cantlin,1,2) # '*-'
             coutput:=coutput+CRLF
             coutput:=coutput+'*-------------------------'+CRLF
          endif
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          if substr(cdeslin,1,2) # '*-'
             coutput:=coutput+'*-------------------------'+CRLF
          endif
       case substr(cllinea,1,16)='STATIC FUNCTION '
          if substr(cantlin,1,2) # '*-'
             coutput:=coutput+CRLF
             coutput:=coutput+'*-------------------------'+CRLF
          endif
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          if substr(cdeslin,1,2) # '*-'
             coutput:=coutput+'*-------------------------'+CRLF
          endif

       case substr(cllinea,1,10)='PROCEDURE '
          if substr(cantlin,1,2) # '*-'
             coutput:=coutput+CRLF
             coutput:=coutput+'*-------------------------'+CRLF
          endif
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          if substr(cdeslin,1,2) # '*-'
             coutput:=coutput+'*-------------------------'+CRLF
          endif
       case substr(cllinea,1,9)='METHOD '
          if swclase=0 .and. substr(cantlin,1,2) # '*-'
             coutput:=coutput+CRLF
             coutput:=coutput+'*-------------------------'+CRLF
          endif
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          if swclase=0 .and. substr(cdeslin,1,2) # '*-'
             coutput:=coutput+'*-------------------------'+CRLF
          endif
       case substr(cllinea,1,5)='CLASS'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
          swclase:=1
       case substr(cllinea,1,7)='DO CASE'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
          swcase:=0
       case substr(cllinea,1,7)='ENDCASE'
          ntab:=ntab-6
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF

       case substr(cllinea,1,8)='ENDCLASS'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          swclase:=0
       case substr(cllinea,1,3)='IF '
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,5)='ENDIF' .or. substr(cllinea,1,6)='END IF'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,5)='ENDDO'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,6)='ELSEIF'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3

       case substr(cllinea,1,4)='ELSE'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,4)='FOR '
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+4
       case substr(cllinea,1,4)='NEXT'
          ntab:=ntab-4
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,14)='DEFINE WINDOW '
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3

       case substr(cllinea,1,15)='DEFINE SPLITBOX'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,10)='END WINDOW'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,12)='END SPLITBOX'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,16)='DEFINE STATUSBAR'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,13)='END STATUSBAR'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF

       case substr(cllinea,1,16)='DEFINE MAIN MENU'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,8)='END MENU'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF

       case substr(cllinea,1,5)='POPUP'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,9)='END POPUP'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF

       case substr(cllinea,1,11)='DEFINE TREE'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,8)='END TREE'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,14)='DEFINE TOOLBAR'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,11)='END TOOLBAR'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,20)='DEFINE DROPDOWN MENU'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,14)='DEFINE CONTEXT'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,12)='DEFINE LABEL'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,9)='END LABEL'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,14)='DEFINE TEXTBOX'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,11)='END TEXTBOX'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,14)='DEFINE EDITBOX'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,11)='END EDITBOX'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,13)='DEFINE BUTTON'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,10)='END BUTTON'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,15)='DEFINE CHECKBOX'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,12)='END CHECKBOX'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,14)='DEFINE LISTBOX'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,11)='END LISTBOX'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,15)='DEFINE COMBOBOX'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,12)='END COMBOBOX'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,18)='DEFINE CHECKBUTTON'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,15)='END CHECKBUTTON'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,11)='DEFINE GRID'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,8)='END GRID'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,13)='DEFINE SLIDER'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,10)='END SLIDER'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,14)='DEFINE SPINNER'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,11)='END SPINNER'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,12)='DEFINE IMAGE'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,9)='END IMAGE'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,17)='DEFINE DATEPICKER'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,14)='END DATEPICKER'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,13)='DEFINE BROWSE'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,10)='END BROWSE'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,17)='DEFINE RADIOGROUP'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,14)='END RADIOGROUP'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,12)='DEFINE FRAME'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,9)='END FRAME'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,10)='DEFINE TAB'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,7)='END TAB'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,17)='DEFINE ANIMATEBOX'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,14)='END ANIMATEBOX'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          //    case substr(cllinea,1,5)='PAGE '
          //         coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          //         ntab:=ntab+3
          //    case substr(cllinea,1,8)='END PAGE'
          //         ntab:=ntab-3
          //         coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,16)='DEFINE HYPERLINK'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,13)='END HYPERLINK'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,20)='DEFINE MONTHCALENDAR'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,17)='END MONTHCALENDAR'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,18)='DEFINE PROGRESSBAR'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,15)='END PROGRESSBAR'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,18)='DEFINE RICHEDITBOX'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,15)='END RICHEDITBOX'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,13)='DEFINE PLAYER'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,10)='END PLAYER'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       case substr(cllinea,1,16)='DEFINE IPADDRESS'
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
          ntab:=ntab+3
       case substr(cllinea,1,13)='END IPADDRESS'
          ntab:=ntab-3
          coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
       otherwise
          if len(clinea)>0
             if swc=0
                coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
             else
                coutput:=coutput+replicate(' ',ntab)+clinea1+CRLF
             endif
             lcero:=0
          else
             lcero++
             if lcero<10
                coutput:=coutput+replicate(' ',ntab)+clinea+CRLF
             endif
          endif
    endcase
next i
return coutput


*-------------------------
METHOD goline() CLASS THMI
*-------------------------
local i,long:=mlcount(editbcvc:edit_1:value)
local npos:=0,nposx:=0, nposy:=0,nline
nline:=val(inputbox('Go to line:','Question'))
if nline>long
   nline:=long  &&&& para que no se pase
endif
todo:=editbcvc:edit_1:value
editbcvc:edit_1:setfocus()
for i:=1 to long
    npos:=npos+len(rtrim((memoline(todo,500,i))))
    if i == nline
       editbcvc:edit_1:setfocus()
       editbcvc.edit_1.caretpos:=npos+(i*2)-i+1-2-len(trim((memoline(todo,500,i))))
       exit
    endif
next i
return nil


*-------------------------
METHOD lookchanges() CLASS THMI
*-------------------------
if editbcvc.edit_1.caretpos<>::_ncaretpos
   ::posxy()
endif
return


*-------------------------
METHOD posxy() CLASS THMI
*-------------------------
local i,todo
local ncaretpos:=editbcvc.edit_1.caretpos, npos:=0,nposx:=0, nposy:=0
   todo:=editbcvc:edit_1:value
   long:=mlcount(todo)
   ::_ncaretpos:=ncaretpos
   nposy:=0
   for i:=1 to long
       npos:=npos+len(rtrim(( memoline(todo,500,i)   )))
       if npos > ( ncaretpos -(i-1) )
          nposx:=len((rtrim((memoline(todo,500,i)))))-(npos-(ncaretpos-(i-1)))+1
          nposy:=i
          if nposx=0
             nposy --
             nposx:=len((rtrim((memoline(todo,500,nposy)))))+1
          endif
          exit
       endif
    next i
    editbcvc.StatusBar.Item(1) := ' Lin'+PADR(str(nposy,4),4)+' Col'+PADR(str(nposx,4),4)+' Car'+PADR(str(ncaretpos,4),4)  // MigSoft
return nil


*-------------------------
METHOD txtsearch() CLASS THMI
*-------------------------
::npostext:=0
::ctext:=rtrim(inputbox('text','Search'))
if len(::ctext)=0
   return
endif
::nextsearch()
return nil


*-------------------------
METHOD nextsearch() CLASS THMI
*-------------------------
local todo
todo:=strtran(editbcvc:edit_1:value,CR,"")
::npostext:=myat(upper(::ctext),upper(todo),::npostext+len(::ctext))
if ::npostext>0
   editbcvc:edit_1:setfocus()
   editbcvc.edit_1.caretpos:=::npostext-1
else
   editbcvc:edit_1:setfocus()
   MsgInfo( 'No more matches found.', 'ooHG IDE+' )
endif
return nil


*-------------------------
Function myat(cbusca,ctodo,ninicio)
*-------------------------
local i,nposluna
nposluna:=0
for i:= ninicio to len(ctodo)
    if upper(substr(ctodo,i,len(cbusca)))=upper(cbusca)
       nposluna:=i
       exit
    endif
next i
return nposluna


*-------------------------
METHOD saveandexit(cdfile) CLASS THMI
*-------------------------
if .not. ::lsave
   if MsgYesNo( 'File not saved, save it now?', 'ooHG IDE+' )
      ::savefile(cdfile)
   endif
endif
editbcvc:release()
return

*-------------------------
METHOD databaseview() CLASS THMI
*-------------------------
LOCAL cdfile, npos, i, j

   if iswindowdefined(Form_brow)
      MsgInfo( 'Browse is already running.', 'ooHG IDE+' )
      RETURN NIL
   endif
   curfol:=curdir()
   curdrv:=curdrive()+':\'
   cdFile:=''
   cdFile:=getFile ( { {'dbf files *.dbf','*.dbf'} }  , 'Open Dbf file',,.F.,.F. )
   if len(cdFile)>0
      npos:=at(".",cdfile)
      cdfile:=left(cdfile,npos-1)
      J:=0
      for i:=1 to len(cdfile)
          if substr(cdfile,i,1)=='\'
             j:=i
          endif
      next i
      cdfile:=substr(cdfile,j+1,len(cdfile))
      USE &cdfile SHARED
      SET INTERACTIVECLOSE ON
      EDIT EXTENDED WORKAREA &cdfile TITLE 'Browsing of ... '+cdfile
      SET INTERACTIVECLOSE OFF
      CLOSE DATABASES
   endif
   DIRCHANGE( curdrv + curfol )
RETURN NIL

*-------------------------
METHOD exitview() CLASS THMI
*-------------------------
form_brow:release()
return


*-------------------------
METHOD disable_button() CLASS THMI
*-------------------------
Form_Tree:button_7:enabled := .F.
Form_Tree:button_9:enabled := .F.
Form_Tree:button_10:enabled := .F.
Form_Tree:button_11:enabled := .F.
return


*-------------------------
METHOD exitform() CLASS THMI
*-------------------------
if .not. myform:lFsave
   if MsgYesNo( 'Form not saved, save it now?', 'ooHG IDE+' )
      myform:save(0)
   endif

endif
   if RTL#NIL
      release window all
   endif
if iswindowactive(lista)
   release window lista
endif
if iswindowactive(form_1)
   release window form_1
endif


cvccontrols:hide()

form_main:hide()
Form_Tree:button_7:enabled := .T.
Form_Tree:button_9:enabled := .T.
Form_Tree:button_10:enabled := .T.
Form_Tree:button_11:enabled := .T.
::form_activated:=.F.
return

*-------------------------
static Function databaseview2( myIde )
*-------------------------
local cdfile,npos,i,j,lDeleted
if iswindowdefined(Form_brow)
   MsgInfo( 'Browse is already running.', 'ooHG IDE+' )
   return nil
endif
curfol:=curdir()
curdrv:=curdrive()+':\'   //MigSoft
cdFile:=''
cdFile:=getFile ( { {'dbf files *.dbf','*.dbf'} }  , 'Open Dbf file',,.F.,.F. )
if len(cdFile)>0
   npos:=at(".",cdfile)
   cdfile:=left(cdfile,npos-1)
   J:=0
   for i:=1 to len(cdfile)
       if substr(cdfile,i,1)=='\'
          j:=i
       endif
   next i
   lDeleted := SET( _SET_DELETED, .F. )                  // make deleted records visible
   cdfile:=substr(cdfile,j+1,len(cdfile))
   use &cdfile SHARED
   AfieldNames := &cdfile->(ARRAY(FCOUNT()))
   aTypes := &cdfile->(ARRAY(FCOUNT()))
   aWidths := &cdfile->(ARRAY(FCOUNT()))
   aDecimals := &cdfile->(ARRAY(FCOUNT()))
   &cdfile->(AFIELDS(aFieldNames, aTypes, aWidths, aDecimals))

   aeval( awidths, {|n,i| iif(awidths[i]<=3, awidths[i]:=30,awidths[i]:=awidths[i]*10) } )

   DEFINE WINDOW Form_brow obj Form_brow ;
      AT 0,0 ;
      WIDTH 640 HEIGHT 480 ;
      TITLE 'Quick Browsing of ... '+cdfile ;
      ICON 'Edit' ;
      child NOMAXIMIZE   ;
      on init {|| form_brow:maximize };
      backcolor myIde:asystemcolor

      @ 25,80 BROWSE Browse_1 ;
      OF form_brow  OBJ Obrow ;
      WIDTH 640 ;
      HEIGHT 460 ;
      HEADERS aFieldNames ;
      WIDTHS awidths ;
      WORKAREA &cdfile ;
      FIELDS aFieldnames ;
      VALUE 0 ;
      TOOLTIP 'Dbl Click to modify' ;
      EDIT APPEND DELETE ;
      LOCK ;


      obrow:bettercolumnsautofit()

      @ 40,730 button button_sal ;
      caption 'Exit'  ;
      action ( myIde:exitview() ) width 60 FLAT


      DEFINE LABEL LABEL_QB
         row 490
         col 150
         value  "ALT-A (Add record) - Delete (Delete record) - Dbl_click (Modify record)"
         width 500
      END LABEL

   END WINDOW

   Form_brow:Browse_1:SetFocus()

   CENTER WINDOW Form_brow
   ACTIVATE WINDOW Form_brow
   CLOSE DATABASES
   SET( _SET_DELETED, lDeleted )
endif
DIRCHANGE(curdrv+curfol)
return


*-------------------------
Function mayusculas(wpaquetes,avalues,aformats)
*-------------------------
local i,t
apaquetes:=wpaquetes
aeval( apaquetes, {|a,i| apaquetes[i]:=upper(substr(apaquetes[i],1,1))+lower(substr(apaquetes[i],2))  } )
return { apaquetes,avalues,aformats }


*--------------------------------------------------------------------------------------------------------------------------*
Function myInputWindow ( Title , aLabels , aValues , aFormats , row , col , aValid , TmpNames , aValidMessages , aReadOnly )
*--------------------------------------------------------------------------------------------------------------------------*
local i , l , ControlRow , e := 0 ,LN , CN ,r , c , wHeight , diff, org
org:=mayusculas(alabels,avalues,aformats)
alabels:=org[1]
avalues:=org[2]
aformats:=org[3]
SET INTERACTIVECLOSE ON
l := Len ( aLabels )

Private aResult [l]

For i := 1 to l
    if ValType ( aValues[i] ) == 'C'
       if ValType ( aFormats[i] ) == 'N'
          If aFormats[i] > 32
             e++
          Endif
       EndIf
    EndIf
    if ValType ( aValues[i] ) == 'M'
       e++
    EndIf
Next i
if pcount() == 4
   r := 0
   c := 0
Else
   r := row
   c := col
   wHeight :=  (l*24) + 90 + (e*60)

   if r + wHeight > GetDeskTopHeight() - 35
      diff :=  r + wHeight - GetDeskTopHeight() + 35
      r := r - diff
   EndIf
EndIf
wminus:=0
if getdesktopheight()=480
   wminus=10
   myIde:lvirtual=.T.
endif
   wyw:=(l*24) + 190 + (e*60)
   wheight := getdesktopheight() - myIde:mainheight-150-wminus
   if wyw < wheight
      wyw:= wheight + 1
   endif

      DEFINE WINDOW _inputwindow obj _iw ;
         WIDTH 720 ;
         HEIGHT wheight - 90 ;
         VIRTUAL HEIGHT wyw TITLE title MODAL NOSIZE ;
         ICON 'Edit' ;
         FONT 'Courier new' SIZE 9 ;
         backcolor myIde:asystemcolor

         on key ESCAPE of _inputwindow action {|| _myInputWindowCancel(_iw, aresult ), sale()}

         ControlRow :=  10

         For i := 1 to l
             LN := 'Label_' + Alltrim(Str(i))
             CN := 'Control_' + Alltrim(Str(i))

             @ ControlRow , 10 LABEL &LN OF _inputwindow VALUE aLabels [i] AUTOSIZE

             do case
                case ValType ( aValues [i] ) == 'L'
                   @ ControlRow , 116 CHECKBOX &CN OF _inputwindow CAPTION '' VALUE aValues[i]
                   ControlRow := ControlRow + 28
                case ValType ( aValues [i] ) == 'D'
                   @ ControlRow , 116 DATEPICKER &CN  OF _inputwindow VALUE aValues[i] WIDTH 420
                   ControlRow := ControlRow + 24
                case ValType ( aValues [i] ) == 'N'
                   If ValType ( aFormats [i] ) == 'A'
                      @ ControlRow , 116 COMBOBOX &CN  OF _inputwindow ITEMS aFormats[i] VALUE aValues[i] WIDTH 420  FONT 'Arial' SIZE 9
                      ControlRow := ControlRow + 24
                   ElseIf  ValType ( aFormats [i] ) == 'C'
                      If AT ( '.' , aFormats [i] ) > 0
                         @ ControlRow , 116 TEXTBOX &CN  OF _inputwindow VALUE aValues[i] WIDTH 120 FONT 'Courier new' SIZE 9 NUMERIC  INPUTMASK aFormats [i]  RIGHTALIGN
                      Else
                         // pb - comento esa linea y la cambio por la de abajo
                         //@ ControlRow , 116 TEXTBOX &CN  OF _inputwindow VALUE aValues[i] WIDTH 120 FONT 'Courier new' SIZE 9 MAXLENGTH Len(aFormats [i]) NUMERIC RIGHTALIGN
                         @ ControlRow , 116 TEXTBOX &CN  OF _inputwindow VALUE aValues[i] WIDTH 120 FONT 'Courier new' SIZE 9 NUMERIC  INPUTMASK aFormats [i]  RIGHTALIGN
                      EndIf
                      ControlRow := ControlRow + 24
                   Endif
                case ValType ( aValues [i] ) == 'C'
                   If ValType ( aFormats [i] ) == 'N'
                      If  aFormats [i] <= 32
                         @ ControlRow , 116 TEXTBOX &CN  OF _inputwindow VALUE aValues[i] WIDTH 270 FONT 'Courier new' SIZE 9 MAXLENGTH aFormats [i]
                         ControlRow := ControlRow + 24
                      Else
                         @ ControlRow , 116 EDITBOX &CN  OF _inputwindow WIDTH 420  HEIGHT 40 VALUE aValues[i] FONT 'Courier new' SIZE 9 MAXLENGTH aFormats[i] NOVSCROLL
                         ControlRow := ControlRow + 42
                      EndIf
                   EndIf
                case ValType ( aValues [i] ) == 'M'
                   @ ControlRow , 116 EDITBOX &CN  OF _inputwindow WIDTH 420 HEIGHT 90 VALUE aValues[i] FONT 'Courier new' SIZE 9
                   ControlRow := ControlRow + 88
             endcase

             If ValType ( aReadOnly ) != 'U'
                If aReadOnly [i] == .T.
                   _DisableControl ( CN ,'_inputwindow' )
                EndIf
             EndIf
         Next i

   DEFINE STATUSBAR     ///////////SIZE 10
       STATUSITEM " " WIDTH 500
      statusitem "Ok    " width 70 action { || _myInputWindowOk ( _iw ,  aresult ), sale() }  tooltip "Ok button"
      statusitem "Cancel " width 70 ACTION {||  _myInputWindowCancel(_iw, aresult ), sale()  }  tooltip "Cancel Button"

/////      statusitem "    "
   END STATUSBAR


      END WINDOW


   CENTER WINDOW _InputWindow

ACTIVATE WINDOW _InputWindow

myIde:lvirtual:=.F.
SET INTERACTIVECLOSE OFF
Return ( aResult )

*-----------------------------------------------------------------------------*
Function _myInputWindowOk( oInputWindow, aResult )
*-----------------------------------------------------------------------------*
Local i , l
   l := len( aResult )
   For i := 1 to l
      aResult[ i ] := oInputWindow:Control( 'Control_' + Alltrim( Str( i ) ) ):Value
   Next i
Return Nil

*-----------------------------------------------------------------------------*
Function _myInputWindowCancel( oInputWindow, aResult )
*-----------------------------------------------------------------------------*
   afill( aResult, NIL )
Return Nil


*-------------------------
Function sale()
*-------------------------
release window _inputwindow
if iswindowdefined("form_1")
    mispuntos()
endif
return nil

//------------------------------------------------------------------------------
Function DelExt( cFileName )
//------------------------------------------------------------------------------
   Local nAt
   Local cBase

   nAt := RAt( ".", cFileName )
   If nAt > 0
      cBase := Left( cFileName, nAt - 1 )
   Else
      cBase := cFileName
   EndIf
Return cBase


//------------------------------------------------------------------------------
Function DelPath( cFileName )
//------------------------------------------------------------------------------
Return SubStr( cFileName, RAt( '\', cFileName ) + 1 )


Function AddSlash(cInFolder)

  LOCAL cOutFolder := ALLTRIM(cInFolder)

  IF RIGHT(cOutfolder, 1) != '\'
    cOutFolder += '\'
  ENDIF

RETURN cOutFolder


//------------------------------------------------------------------------------
Function DelSlash( cInFolder )
//------------------------------------------------------------------------------
  LOCAL cOutFolder := AllTrim( cInFolder )

  If Right( cOutfolder, 1 ) == '\'
     cOutFolder := Left( cOutFolder, Len( cOutFolder ) - 1 )
  EndIf

Return cOutFolder


*---------------------------------------------------------------*
Function OnlyFolder(cFile1)
*---------------------------------------------------------------*
   Local i,nLg,cFolder,nPosFile
   If Len(cFile1) > 0
      i := 1
      nLg :=  LEN(cFile1)
      do while ( nLg > i )
         if '\' $ Right(cFile1,i-1)
            nPosFile := i-1
            i := LEN(cFile1)
         endif
         i++
      enddo
      cFolder := Left(cFile1,nLg-nPosfile)
   Else
      cFolder := Nil
   Endif
Return(cFolder)

//------------------------------------------------------------------------------
Function IsFileInPath( cFileName )
//------------------------------------------------------------------------------
   Local cDir
   LOCAL cName
   LOCAL cExt
   LOCAL cFullName
   LOCAL aExt

   hb_FNameSplit( cFileName, @cDir, @cName, @cExt )

   For Each cDir In hb_ATokens( GetEnv( "PATH" ), hb_osPathListSeparator(), .T., .T. )
      If Left( cDir, 1 ) == '"' .AND. Right( cDir, 1 ) == '"'
         cDir := SubStr( cDir, 2, Len( cDir ) - 2 )
      EndIf
      If ! Empty( cDir )
         If ! Right( cDir, 1 ) == "\"
            cDir += "\"
         EndIf
         If File( cDir + cFileName )
            Return .T.
         EndIf
      EndIf
   Next
Return .F.


#pragma BEGINDUMP

#include <windows.h>
#include <winuser.h>
#include "hbapi.h"

#define VK1_A 65
#define VK1_C 67
#define VK1_V 86
#define VK1_X 88

/* select all - ctrl-a */
HB_FUNC( SEND_SELECTALL )
{
   keybd_event(VK_CONTROL, MapVirtualKey(VK_CONTROL, 0), 0, 0);
   keybd_event(VK1_A, MapVirtualKey(VK1_A, 0), 0, 0);
   keybd_event(VK1_A, MapVirtualKey(VK1_A, 0), KEYEVENTF_KEYUP, 0);
   keybd_event(VK_CONTROL, MapVirtualKey(VK_CONTROL, 0), KEYEVENTF_KEYUP,
0);
}

/* copy - ctrl-c */
HB_FUNC( SEND_COPY )
{
   keybd_event(VK_CONTROL, MapVirtualKey(VK_CONTROL, 0), 0, 0);
   keybd_event(VK1_C, MapVirtualKey(VK1_C, 0), 0, 0);
   keybd_event(VK1_C, MapVirtualKey(VK1_C, 0), KEYEVENTF_KEYUP, 0);
   keybd_event(VK_CONTROL, MapVirtualKey(VK_CONTROL, 0), KEYEVENTF_KEYUP,
0);
}

/* paste - ctrl-v */
HB_FUNC( SEND_PASTE )
{
   keybd_event(VK_CONTROL, MapVirtualKey(VK_CONTROL, 0), 0, 0);
   keybd_event(VK1_V, MapVirtualKey(VK1_V, 0), 0, 0);
   keybd_event(VK1_V, MapVirtualKey(VK1_V, 0), KEYEVENTF_KEYUP, 0);
   keybd_event(VK_CONTROL, MapVirtualKey(VK_CONTROL, 0), KEYEVENTF_KEYUP,
0);
}

/* cut - ctrl-x */
HB_FUNC( SEND_CUT )
{
   keybd_event(VK_CONTROL, MapVirtualKey(VK_CONTROL, 0), 0, 0);
   keybd_event(VK1_X, MapVirtualKey(VK1_X, 0), 0, 0);
   keybd_event(VK1_X, MapVirtualKey(VK1_X, 0), KEYEVENTF_KEYUP, 0);
   keybd_event(VK_CONTROL, MapVirtualKey(VK_CONTROL, 0), KEYEVENTF_KEYUP,
0);
}

HB_FUNC ( ZAPDIRECTORY )
{
   SHFILEOPSTRUCT sh;

   sh.hwnd = GetActiveWindow();
   sh.wFunc = FO_DELETE;
   sh.pFrom = hb_parc( 1 );
   sh.pTo = NULL;
   sh.fFlags = FOF_NOCONFIRMATION | FOF_SILENT;
   sh.hNameMappings = 0;
   sh.lpszProgressTitle = NULL;

   SHFileOperation( &sh );
}


#pragma ENDDUMP

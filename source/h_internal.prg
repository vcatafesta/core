/*
 * $Id: h_internal.prg,v 1.1 2006-07-26 01:20:57 guerra000 Exp $
 */
/*
 * ooHG source code:
 * Internal window functions
 *
 * Copyright 2006 Vicente Guerra <vicente@guerra.com.mx>
 * www - http://www.guerra.com.mx
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307 USA (or visit the web site http://www.gnu.org/).
 *
 * As a special exception, the ooHG Project gives permission for
 * additional uses of the text contained in its release of ooHG.
 *
 * The exception is that, if you link the ooHG libraries with other
 * files to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the ooHG library code into it.
 *
 * This exception does not however invalidate any other reasons why
 * the executable file might be covered by the GNU General Public License.
 *
 * This exception applies only to the code released by the ooHG
 * Project under the name ooHG. If you copy code from other
 * ooHG Project or Free Software Foundation releases into a copy of
 * ooHG, as the General Public License permits, the exception does
 * not apply to the code that you add in this way. To avoid misleading
 * anyone as to the status of such modified files, you must delete
 * this exception notice from them.
 *
 * If you write modifications of your own for ooHG, it is your choice
 * whether to permit this exception to apply to your modifications.
 * If you do not wish that, delete this exception notice.
 *
 */

#include 'oohg.ch'
#include 'hbclass.ch'
#include "i_windefs.ch"
#include "common.ch"

*------------------------------------------------------------------------------*
CLASS TInternal FROM TControl
*------------------------------------------------------------------------------*
   DATA Type      INIT "INTERNAL" READONLY
   DATA nVirtualHeight INIT 0
   DATA nVirtualWidth  INIT 0
   DATA RangeHeight    INIT 0
   DATA RangeWidth     INIT 0
   DATA HScrollBar     INIT nil
   DATA VScrollBar     INIT nil

   METHOD Define
   METHOD RefreshData
   METHOD Events_VScroll
   METHOD Events_HScroll
   METHOD VirtualWidth        SETGET
   METHOD VirtualHeight       SETGET
ENDCLASS

*------------------------------------------------------------------------------*
METHOD Define( ControlName, ParentForm, x, y, OnClick, w, h, ;
               backcolor, tooltip, gotfocus, lostfocus, ;
               Transparent, BORDER, CLIENTEDGE, icon, ;
               Virtualheight, VirtualWidth, ;
               MouseDragProcedure, MouseMoveProcedure, ;
               NoTabStop, HelpId, invisible, lRtl ) CLASS TInternal
*------------------------------------------------------------------------------*
Local ControlHandle, nStyle, nStyleEx := 0

   ASSIGN ::nCol        VALUE x TYPE "N"
   ASSIGN ::nRow        VALUE y TYPE "N"
   ASSIGN ::nWidth      VALUE w TYPE "N"
   ASSIGN ::nHeight     VALUE h TYPE "N"
   ASSIGN Invisible     VALUE Invisible   TYPE "L" DEFAULT .F.
   ASSIGN ::Transparent VALUE Transparent TYPE "L" DEFAULT .F.

   if valtype( VirtualHeight ) != "N"
      VirtualHeight := 0
	endif

   if valtype( VirtualWidth ) != "N"
      VirtualWidth := 0
   endif

   ::SetForm( ControlName, ParentForm,,,, backcolor,, lRtl )

   nStyle := if( ValType( NoTabStop ) != "L" .OR. ! NoTabStop, WS_TABSTOP, 0 ) + ;
             if( ValType( invisible ) != "L" .OR. ! invisible, WS_VISIBLE, 0 ) + ;
             if( ValType( BORDER ) == "L"    .AND. BORDER,     WS_BORDER, 0 )  + ;
             SS_NOTIFY

   nStyleEx += if( ValType( CLIENTEDGE ) == "L" .AND. CLIENTEDGE, WS_EX_CLIENTEDGE, 0 ) + ;
               if( ::Transparent, WS_EX_TRANSPARENT, 0 )
   If _OOHG_SetControlParent()
      // This is not working when there's a RADIO control :(
      nStyleEx += WS_EX_CONTROLPARENT
   EndIf

   // This window is a LABEL!!!
   Controlhandle := InitLabel( ::ContainerhWnd, "", 0, ::ContainerCol, ::ContainerRow, ::nWidth, ::nHeight, '', 0, Nil , nStyle, nStyleEx, ::lRtl )

   ::Register( ControlHandle, ControlName, HelpId, ! Invisible, ToolTip )

   ::OnClick := OnClick
   ::OnLostFocus := LostFocus
   ::OnGotFocus :=  GotFocus
   ::OnMouseDrag := MouseDragProcedure
   ::OnMouseMove := MouseMoveProcedure

   ::HScrollBar            := TScrollBar()
   ::HScrollBar:hWnd       := ::hWnd
   ::HScrollBar:ScrollType := SB_HORZ
   ::HScrollBar:nOrient    := SB_HORZ
   ::HScrollBar:nLineSkip  := 1
   ::HScrollBar:nPageSkip  := 20

   ::VScrollBar            := TScrollBar()
   ::VScrollBar:hWnd       := ::hWnd
   ::VScrollBar:ScrollType := SB_VERT
   ::VScrollBar:nOrient    := SB_VERT
   ::VScrollBar:nLineSkip  := 1
   ::VScrollBar:nPageSkip  := 20

   ::nVirtualHeight := VirtualHeight
   ::nVirtualWidth  := VirtualWidth
   ValidateScrolls( Self, .F. )

   ::hCursor := LoadCursorFromFile( icon )

   // Add to browselist array to update on window activation
   aAdd( ::Parent:BrowseList, Self )

   If ::Transparent
      RedrawWindowControlRect( ::ContainerhWnd, ::ContainerRow, ::ContainerCol, ::ContainerRow + ::Height, ::ContainerCol + ::Width )
   EndIf

   ::ContainerhWndValue := ::hWnd
   _OOHG_AddFrame( Self )
Return Self

*-----------------------------------------------------------------------------*
METHOD RefreshData() CLASS TInternal
*-----------------------------------------------------------------------------*
   AEVAL( ::aControls, { |o| o:RefreshData() } )
Return nil

// sizepos: validatescroll
//

*-----------------------------------------------------------------------------*
METHOD Events_VScroll( wParam ) CLASS TInternal
*-----------------------------------------------------------------------------*
Local uRet
   uRet := ::VScrollBar:Events_VScroll( wParam )
   ::RowMargin := - ::VScrollBar:Value
   AEVAL( ::aControls, { |o| If( o:Container == nil, o:SizePos(), ) } )
   ReDrawWindow( ::hWnd )
Return uRet

*-----------------------------------------------------------------------------*
METHOD Events_HScroll( wParam ) CLASS TInternal
*-----------------------------------------------------------------------------*
Local uRet
   uRet := ::HScrollBar:Events_HScroll( wParam )
   ::ColMargin := - ::HScrollBar:Value
   AEVAL( ::aControls, { |o| If( o:Container == nil, o:SizePos(), ) } )
   ReDrawWindow( ::hWnd )
Return uRet

*------------------------------------------------------------------------------*
METHOD VirtualWidth( nSize ) CLASS TInternal
*------------------------------------------------------------------------------*
   If valtype( nSize ) == "N"
      ::nVirtualWidth := nSize
      ValidateScrolls( Self, .T. )
   EndIf
Return ::nVirtualWidth

*------------------------------------------------------------------------------*
METHOD VirtualHeight( nSize ) CLASS TInternal
*------------------------------------------------------------------------------*
   If valtype( nSize ) == "N"
      ::nVirtualHeight := nSize
      ValidateScrolls( Self, .T. )
   EndIf
Return ::nVirtualHeight

*-----------------------------------------------------------------------------*
Function _EndInternal()
*-----------------------------------------------------------------------------*
Return _OOHG_DeleteFrame( "INTERNAL" )
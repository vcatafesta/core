/*
 * $Id: i_scroll.ch,v 1.1 2007-07-01 19:37:04 guerra000 Exp $
 */
/*
 * ooHG source code:
 * Scrollbar control definition
 *
 * Copyright 2007 Vicente Guerra <vicente@guerra.com.mx>
 * www - http://www.guerra.com.mx
 *
 * Portions of this code are copyrighted by the Harbour MiniGUI library.
 * Copyright 2002-2005 Roberto Lopez <roblez@ciudad.com.ar>
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

#command @ <row>, <col> SCROLLBAR <name>                ;
                        [ OBJ <obj> ]                   ;
                        [ <dummy1: OF, PARENT> <parent> ] ;
                        [ HEIGHT <height> ]             ;
                        [ WIDTH <width> ]               ;
                        [ RANGE <min> , <max> ]         ;
                        [ ON CHANGE <change> ]          ;
                        [ ON <dummy2: LINEUP, LINELEFT> <lineup> ] ;
                        [ ON <dummy3: LINEDOWN, LINERIGHT> <linedown> ] ;
                        [ ON <dummy4: PAGEUP, PAGELEFT> <pageup> ] ;
                        [ ON <dummy5: PAGEDOWN, PAGERIGHT> <pagedown> ] ;
                        [ ON <dummy6: TOP, LEFT> <top> ] ;
                        [ ON <dummy7: BOTTOM, RIGHT> <bottom> ] ;
                        [ ON THUMB <thumb> ]            ;
                        [ ON TRACK <track> ]            ;
                        [ ON ENDTRACK <endtrack> ]      ;
                        [ HELPID <helpid> ]             ;
                        [ <invisible: INVISIBLE> ]      ;
                        [ TOOLTIP <tooltip> ]           ;
                        [ <rtl: RTL> ]                  ;
                        [ <horz: HORIZONTAL> ]          ;
                        [ <vert: VERTICAL> ]            ;
                        [ <attached: ATTACHED> ]        ;
                        [ VALUE <value> ]               ;
                        [ <disabled: DISABLED> ]        ;
                        [ SUBCLASS <subclass> ]         ;
                        [ LINESKIP <lineskip> ]         ;
                        [ PAGESKIP <pageskip> ]         ;
                        [ <auto: AUTOMOVE> ]            ;
         =>;
        [ <obj> := ] _OOHG_SelectSubClass( TScrollBar(), [ <subclass>() ] ): ;
                     Define( <(name)>, <(parent)>, <col>, <row>, <width>, <height>, ;
                     <min>, <max>, <{change}>, <{lineup}>, <{linedown}>, <{pageup}>, <{pagedown}>, ;
                     <{top}>, <{bottom}>, <{thumb}>, <{track}>, <{endtrack}>, <helpid>, ;
                     <.invisible.>, <tooltip>, <.rtl.>, iif( <.horz.>, 0, iif( <.vert.>, 1, nil ) ), ;
                     <.attached.>, <value>, <disabled>, <lineskip>, <pageskip>, <.auto.> )
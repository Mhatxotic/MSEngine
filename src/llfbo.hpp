/* == LLFBO.HPP ============================================================ **
** ######################################################################### **
** ## MS-ENGINE              Copyright (c) MS-Design, All Rights Reserved ## **
** ######################################################################### **
** ## Defines the 'Fbo' namespace and methods for the guest to use in     ## **
** ## Lua. This file is invoked by 'lualib.hpp'.                          ## **
** ######################################################################### **
** ------------------------------------------------------------------------- */
#pragma once                           // Only one incursion allowed
/* ========================================================================= **
** ######################################################################### **
** ========================================================================= */
// % Fbo
/* ------------------------------------------------------------------------- */
// ! The fbo class allows the programmer to create an OpenGL frame-buffer
// ! object which they can use to create seperate drawing canvases which they
// ! can apply special effects to without modifying other canvases.
/* ========================================================================= */
namespace LLFbo {                      // Fbo namespace
/* -- Dependencies --------------------------------------------------------- */
using namespace IConsole::P;           using namespace IFboDef::P;
using namespace IFbo::P;               using namespace IFboCore::P;
using namespace ILua::P;               using namespace IOgl::P;
using namespace ISShot::P;             using namespace IString::P;
using namespace Common;
/* ========================================================================= **
** ######################################################################### **
** ## Fbo common helper classes                                           ## **
** ######################################################################### **
** -- Create Fbo class argument ------------------------------------------- */
struct AcFbo : public ArClass<Fbo> {
  explicit AcFbo(lua_State*const lS) :
    ArClass{*LuaUtilClassCreate<Fbo>(lS, *cFbos)}{} };
/* -- Read a blending id --------------------------------------------------- */
struct AgBlend : public AgIntegerLGE<OglBlendEnum>
  { explicit AgBlend(lua_State*const lS, const int iArg) :
      AgIntegerLGE{ lS, iArg, OB_Z, OB_S_A_S }{} };
/* ========================================================================= **
** ######################################################################### **
** ## Fbo:* member functions                                              ## **
** ######################################################################### **
** ========================================================================= */
// $ Fbo:Destroy
// ? Destroys the FBO and frees all the memory associated with it. The OpenGL
// ? handles and VRAM allocated by it are freed after the main FBO has has
// ? been rendered. The object will no longer be useable after this call and an
// ? error will be generated if accessed.
/* ------------------------------------------------------------------------- */
LLFUNC(Destroy, 0, LuaUtilClassDestroy<Fbo>(lS, 1, *cFbos))
/* ========================================================================= */
// $ Fbo.SetBlend
// > srcRGB:integer=How the source RGB blending factors are computed.
// > dstRGB:integer=How the dest RGB blending factors are computed.
// > srcAlpha:integer=How the alpha source blending factor is computed.
// > dstAlpha:integer=How the alpha destination blending factor is computed.
// ? Sets the alpha blending function formula of the back buffer using
// ? glBlendFuncSeparate. The parameters are a zero index of the formula you
// ? want to use. These values are available in the 'Fbo.Blends' table.
/* ------------------------------------------------------------------------- */
LLFUNC(SetBlend, 0,
  const AgFbo aFbo{lS, 1};
  const AgBlend aSrcRGB{lS, 2},
                aDstRGB{lS, 3},
                aSrcAlpha{lS, 4},
                aDstAlpha{lS, 5};
  aFbo().FboSetBlend(aSrcRGB, aDstRGB, aSrcAlpha, aDstAlpha))
/* ========================================================================= */
// $ Fbo:SetVX
// > TriIndex:integer=Triangle index. Triangle #1 (zero) or triangle #2 (one).
// > V1Left:number=Coord #1 of vertex #1 of the specified triangle.
// > V1Top:number=Coord #2 of vertex #2 of the specified triangle.
// > V2Left:number=Coord #1 of vertex #3 of the specified triangle.
// > V2Top:number=Coord #2 of vertex #1 of the specified triangle.
// > V3Left:number=Coord #1 of vertex #2 of the specified triangle.
// > V3Top:number=Coord #2 of vertex #3 of the specified triangle.
// ? Stores the specified vertex co-ordinates when using the 'Fbo:Blit'
// ? function.
/* ------------------------------------------------------------------------- */
LLFUNC(SetVX, 0,
  const AgFbo aFbo{lS, 1};
  const AgTriangleId aTriangleId{lS, 2};
  const FboBase::TriPosData tpdVertices{
    AgGLfloat{lS, 3}, AgGLfloat{lS, 4}, AgGLfloat{lS, 5},
    AgGLfloat{lS, 6}, AgGLfloat{lS, 7}, AgGLfloat{lS, 8},
  };
  aFbo().FboItemSetVertexEx(aTriangleId, tpdVertices))
/* ========================================================================= */
// $ Fbo:SetTCX
// > TriIndex:integer=Triangle index. Triangle #1 (zero) or triangle #2 (one).
// > TC1Left:number=Coord #1 of vertex #1 of the specified triangle.
// > TC1Top:number=Coord #2 of vertex #2 of the specified triangle.
// > TC2Left:number=Coord #1 of vertex #3 of the specified triangle.
// > TC2Top:number=Coord #2 of vertex #1 of the specified triangle.
// > TC3Left:number=Coord #1 of vertex #2 of the specified triangle.
// > TC3Top:number=Coord #2 of vertex #3 of the specified triangle.
// ? Stores the specified texture co-ordinates for when the frame buffer object
// ? is drawn.
/* ------------------------------------------------------------------------- */
LLFUNC(SetTCX, 0,
  const AgFbo aFbo{lS, 1};
  const AgTriangleId aTriangleId{lS, 2};
  const FboBase::TriCoordData tcdCoords{
    AgGLfloat{lS, 3}, AgGLfloat{lS, 4}, AgGLfloat{lS, 5},
    AgGLfloat{lS, 6}, AgGLfloat{lS, 7}, AgGLfloat{lS, 8},
  };
  aFbo().FboItemSetTexCoordEx(aTriangleId, tcdCoords))
/* ========================================================================= */
// $ Fbo:SetCX
// > TriIndex:integer=Triangle index. Triangle #1 (zero) or triangle #2 (one).
// > V1Red:number=Red component of vertex #1 of the specified triangle.
// > V1Green:number=Green component of vertex #1 of the specified triangle.
// > V1Blue:number=Blue component of vertex #1 of the specified triangle.
// > V1Alpha:number=Alpha component of vertex #1 of the specified triangle.
// > V2Red:number=Red component of vertex #2 of the specified triangle.
// > V2Green:number=Green component of vertex #2 of the specified triangle.
// > V2Blue:number=Blue component of vertex #2 of the specified triangle.
// > V2Alpha:number=Alpha component of vertex #2 of the specified triangle.
// > V3Red:number=Red component of vertex #3 of the specified triangle.
// > V3Green:number=Green component of vertex #3 of the specified triangle.
// > V3Blue:number=Blue component of vertex #3 of the specified triangle.
// > V3Alpha:number=Alpha component of vertex #3 of the specified triangle.
// ? Stores the specified colour intensities on each vertex for the
// ? Fbo:Blit() function.
/* ------------------------------------------------------------------------- */
LLFUNC(SetCX, 0,
  const AgFbo aFbo{lS, 1};
  const AgTriangleId aTriangleId{lS, 2};
  const FboBase::TriColData tcdColour{
    AgGLfloat{lS,  3}, AgGLfloat{lS,  4}, AgGLfloat{lS,  5}, AgGLfloat{lS,  6},
    AgGLfloat{lS,  7}, AgGLfloat{lS,  8}, AgGLfloat{lS,  9}, AgGLfloat{lS, 10},
    AgGLfloat{lS, 11}, AgGLfloat{lS, 12}, AgGLfloat{lS, 13}, AgGLfloat{lS, 14}
  };
  aFbo().FboItemSetColourEx(aTriangleId, tcdColour))
/* ========================================================================= */
// $ Fbo:SetVLTRB
// > Left:number=The destination left co-ordinate.
// > Top:number=The destination top co-ordinate.
// > Right:number=The destination right co-ordinate.
// > Bottom:number=The destination bottom co-ordinate.
// ? Allows you to set basic vertex bounds when blitting the frame buffer
// ? object.
/* ------------------------------------------------------------------------- */
LLFUNC(SetVLTRB, 0,
  const AgFbo aFbo{lS, 1};
  const AgGLfloat aLeft{lS, 2},
                  aTop{lS, 3},
                  aRight{lS, 4},
                  aBottom{lS, 5};
  aFbo().FboItemSetVertex(aLeft, aTop, aRight, aBottom))
/* ========================================================================= */
// $ Fbo:SetVLTWH
// > Left:number=The destination left co-ordinate.
// > Top:number=The destination top co-ordinate.
// > Width:number=The destination width.
// > Height:number=The destination height.
// ? Allows you to set basic vertex co-ordinates and dimensions when blitting
// ? the frame buffer object.
/* ------------------------------------------------------------------------- */
LLFUNC(SetVLTWH, 0,
  const AgFbo aFbo{lS, 1};
  const AgGLfloat aLeft{lS, 2},
                  aTop{lS, 3},
                  aWidth{lS, 4},
                  aHeight{lS, 5};
  aFbo().FboItemSetVertexWH(aLeft, aTop, aWidth, aHeight))
/* ========================================================================= */
// $ Fbo:SetVLTRBA
// > Left:number=The destination left co-ordinate.
// > Top:number=The destination top co-ordinate.
// > Right:number=The destination right co-ordinate.
// > Bottom:number=The destination bottom co-ordinate.
// > Angle:number=The angle of the vertex.
// ? Allows you to set basic vertex co-ordinates when blitting the fbo with
// ? angle calculations.
/* ------------------------------------------------------------------------- */
LLFUNC(SetVLTRBA, 0,
  const AgFbo aFbo{lS, 1};
  const AgGLfloat aLeft{lS, 2},
                  aTop{lS, 3},
                  aRight{lS, 4},
                  aBottom{lS, 5};
  const AgAngle aAngle{lS, 6};
  aFbo().FboItemSetVertex(aLeft, aTop, aRight, aBottom, aAngle))
/* ========================================================================= */
// $ Fbo:SetVLTWHA
// > Left:number=The destination left co-ordinate.
// > Top:number=The destination top co-ordinate.
// > Width:number=The destination width.
// > Height:number=The destination height.
// > Angle:number=The angle of the vertex.
// ? Allows you to set basic vertex co-ordinates when blitting the fbo with
// ? angle calculations.
/* ------------------------------------------------------------------------- */
LLFUNC(SetVLTWHA, 0,
  const AgFbo aFbo{lS, 1};
  const AgGLfloat aLeft{lS, 2},
                  aTop{lS, 3},
                  aWidth{lS, 4},
                  aHeight{lS, 5};
  const AgAngle aAngle{lS, 6};
  aFbo().FboItemSetVertexWH(aLeft, aTop, aWidth, aHeight, aAngle))
/* ========================================================================= */
// $ Fbo:SetMatrix
// > Left:number=The left co-ordinate.
// > Top:number=The top co-ordinate.
// > Right:number=The right co-ordinate.
// > Bottom:number=The bottom co-ordinate.
// ? Sets the matrix of the specified fbo, meaning, these are the bounds of
// ? where you can draw. Same as glOrtho().
// ? See: https://www.opengl.org/sdk/docs/man2/xhtml/glOrtho.xml
/* ------------------------------------------------------------------------- */
LLFUNC(SetMatrix, 0,
  const AgFbo aFbo{lS, 1};
  const AgGLfloat aLeft{lS, 2},
                  aTop{lS, 3},
                  aRight{lS, 4},
                  aBottom{lS, 5};
  aFbo().FboSetMatrix(aLeft, aTop, aRight, aBottom));
/* ========================================================================= */
// $ Fbo:SetWireframe
// > Wireframe:Boolean=Use polygon mode GL_LINE (true) or GL_FILL (false).
// ? Sets drawing the contents in the fbo in wireframe more or texture filled
// ? mode (default).
/* ------------------------------------------------------------------------- */
LLFUNC(SetWireframe, 0, AgFbo{lS, 1}().FboSetWireframe(AgBoolean{lS, 2}))
/* ========================================================================= */
// $ Fbo:SetTCLTRB
// > Left:number=The destination left co-ordinate.
// > Top:number=The destination top co-ordinate.
// > Right:number=The destination right co-ordinate.
// > Bottom:number=The destination bottom co-ordinate.
// ? Stores the specified texture bounds used when blitting the frame buffer
// ? object.
/* ------------------------------------------------------------------------- */
LLFUNC(SetTCLTRB, 0,
  const AgFbo aFbo{lS, 1};
  const AgGLfloat aLeft{lS, 2},
                  aTop{lS, 3},
                  aRight{lS, 4},
                  aBottom{lS, 5};
  aFbo().FboItemSetTexCoord(aLeft, aTop, aRight, aBottom))
/* ========================================================================= */
// $ Fbo:SetTCLTWH
// > Left:number=The left destination co-ordinate.
// > Top:number=The top destination co-ordinate.
// > Width:number=The destination width.
// > Height:number=The destination height.
// ? Stores the specified texture co-ords and dimensions when blitting the
// ? frame buffer object.
/* ------------------------------------------------------------------------- */
LLFUNC(SetTCLTWH, 0,
  const AgFbo aFbo{lS, 1};
  const AgGLfloat aLeft{lS, 2},
                  aTop{lS, 3},
                  aWidth{lS, 4},
                  aHeight{lS, 5};
  aFbo().FboItemSetTexCoordWH(aLeft, aTop, aWidth, aHeight))
/* ========================================================================= */
// $ Fbo:SetClear
// > State:bool=New clear state
// ? Sets if the fbo should be cleared before rendering to it
/* ------------------------------------------------------------------------- */
LLFUNC(SetClear, 0, AgFbo{lS, 1}().FboSetClear(AgBoolean{lS, 2}))
/* ========================================================================= */
// $ Fbo:SetClearColour
// > Red:number=The red component intensity (0 to 1).
// > Green:number=The green component intensity (0 to 1).
// > Blue:number=The blue component intensity (0 to 1).
// > Alpha:number=The alpha component intensity (0 to 1).
// ? Same as glClearColour(). Allows you to set the colour for glClear(),
// ? meaning the fbo is cleared with this colour on each new frame loop.
// ? See: https://www.opengl.org/sdk/docs/man2/xhtml/glClear.xml.
// ? See: https://www.opengl.org/sdk/docs/man2/xhtml/glClearColor.xml.
/* ------------------------------------------------------------------------- */
LLFUNC(SetClearColour, 0,
  const AgFbo aFbo{lS, 1};
  const AgGLfloat aRed{lS, 2},
                  aGreen{lS, 3},
                  aBlue{lS, 4},
                  aAlpha{lS, 5};
  aFbo().FboSetClearColour(aRed, aGreen, aBlue, aAlpha))
/* ========================================================================= */
// $ Fbo:SetCRGBA
// > Red:number=The entire fbo texture red colour intensity (0 to 1).
// > Green:number=The entire fbo texture green colour intensity (0 to 1).
// > Blue:number=The entire fbo texture blue colour intensity (0 to 1).
// > Alpha:number=The entire fbo texture alpha colour intensity (0 to 1).
// ? Sets the colour intensity of all the vertexes for the entire fbo texture.
/* ------------------------------------------------------------------------- */
LLFUNC(SetCRGBA, 0,
  const AgFbo aFbo{lS, 1};
  const AgGLfloat aRed{lS, 2},
                  aGreen{lS, 3},
                  aBlue{lS, 4},
                  aAlpha{lS, 5};
  aFbo().FboItemSetQuadRGBA(aRed, aGreen, aBlue, aAlpha))
/* ========================================================================= */
// $ Fbo:SetFilter
// > Id:integer=The texture filter id.
// ? Sets the texture filtering id for the fbo texture. Mipmaps are
// ? automatically generated if a mipmapping id is selected.
// ? (Magnification / Minification). See 'Texture.Filters()' for more info.
/* ------------------------------------------------------------------------- */
LLFUNC(SetFilter, 0, AgFbo{lS, 1}().FboSetFilterCommit(AgFilterId{lS, 2}))
/* ========================================================================= */
// $ Fbo:Activate
// ? Makes the specified fbo the active fbo and all subsequent Texture:* calls
// ? will apply to this fbo. This can be called on the main fbo.
/* ------------------------------------------------------------------------- */
LLFUNC(Activate, 0, AgFbo{lS, 1}().FboSetActive())
/* ========================================================================= */
// $ Fbo:Finish
// ? Queues the fbo for redrawing after LUA has finished it's tick function.
// ? You only need to run this once, subsequent calls in the same frame will
// ? be ignored as the fbo has already been queued for redrawing.
/* ------------------------------------------------------------------------- */
LLFUNC(Finish, 0, AgFbo{lS, 1}().FboFinishAndRender())
/* ========================================================================= */
// $ Fbo:Blit
// ? Blits the SPECIFIED fbo to the currently ACTIVE fbo. This just adds
// ? to the active FBO drawing arrays and doesn't actually render until the
// ? active fbo is finished and rendered. The currently stored vertex,
// ? texcoord, colour and matrix values are used.
/* ------------------------------------------------------------------------- */
LLFUNC(Blit, 0, FboActive()->FboBlit(AgFbo{lS, 1}()))
/* ========================================================================= */
// $ Fbo:BlitT
// > TriIndex:integer=Triangle index. Triangle #1 (zero) or triangle #2 (one).
// ? Blits the SPECIFIED triangle of the SPECIFIED fbo to the currently
// ? ACTIVE fbo. This just adds to the active FBO drawing arrays and doesn't
// ? actually render until the active fbo is finished and rendered. The
// ? currently stored vertex, texcoord, colour and matrix values are used.
/* ------------------------------------------------------------------------- */
LLFUNC(BlitT, 0,
  const AgFbo aFbo{lS, 1};
  const AgTriangleId aTriangleId{lS, 2};
  FboActive()->FboBlitTri(aFbo(), aTriangleId))
/* ========================================================================= */
// $ Fbo:GetLFloatCount
// < Count:integer=Number of floats in display lists.
// ? Returns the number of floating point numbers entered into the display list
// ? on the last rendered frame.
/* ------------------------------------------------------------------------- */
LLFUNC(GetLFloatCount, 1, LuaUtilPushVar(lS, AgFbo{lS, 1}().FboGetTris()))
/* ========================================================================= */
// $ Fbo:GetFloatCount
// < Count:integer=Number of floats in display lists.
// ? Returns the number of floating point numbers currently entered into the
// ? display list.
/* ------------------------------------------------------------------------- */
LLFUNC(GetFloatCount, 1, LuaUtilPushVar(lS, AgFbo{lS, 1}().FboGetTrisNow()))
/* ========================================================================= */
// $ Fbo:IsFinished
// < State:boolean=Is the fbo finished
// ? Returns if the fbo has been finished.
/* ------------------------------------------------------------------------- */
LLFUNC(IsFinished, 1,
  LuaUtilPushVar(lS, !!AgFbo{lS, 1}().FboGetFinishCount()))
/* ========================================================================= */
// $ Fbo:GetMatrix
// < Width:number=Total count of horizontal viewable pixels.
// < Height:number=Total count of vertical viewable pixels.
// < Left:number=Minimum viewable matrix X position.
// < Top:number=Minimum viewable matrix Y position.
// < Right:number=Maximum viewable matrix X position.
// < Bottom:number=Maximum viewable matrix Y position.
// < MatrixWidth:number=Current requested matrix width.
// < MatrixHeight:number=Current requested matrix height.
// ? Returns the current matrix information for the specified fbo.
/* ------------------------------------------------------------------------- */
LLFUNC(GetMatrix, 6,
  const Fbo &fboCref = AgFbo{lS, 1}();
  const FboFloatCoords &ffcRef = fboCref.ffcStage;
  LuaUtilPushVar(lS, fboCref.GetCoRight(), fboCref.GetCoBottom(),
    ffcRef.GetCoLeft(), ffcRef.GetCoTop(), ffcRef.GetCoRight(),
    ffcRef.GetCoBottom()))
/* ========================================================================= */
// $ Fbo:Reserve
// > Vertexes:integer=How many 64-bit floats to reserve in GPU float list
// > Commands:integer=How many structs to reserve in GPU commands list
// ? Reserves memory the respective number of items. Use this if the first
// ? complex frame you draw is slow. It's probably because of this as the
// ? default reservation level for the lists is 1024 x 64-bit float/command.
/* ------------------------------------------------------------------------- */
LLFUNC(Reserve, 0,
  const AgFbo aFbo{lS, 1};
  const AgSizeTLG aVertexes{lS, 2, 0, 1000000},
                  aCommands{lS, 3, 0, 1000000};
  aFbo().FboReserve(aVertexes, aCommands))
/* ========================================================================= */
// $ Fbo:GetId
// < Id:integer=The id number of the Fbo object.
// ? Returns the unique id of the Fbo object.
/* ------------------------------------------------------------------------- */
LLFUNC(GetId, 1, LuaUtilPushVar(lS, AgFbo{lS, 1}().CtrGet()))
/* ========================================================================= */
// $ Fbo:GetName
// < Id:string=The video identifier
// ? Returns the identifier of the Fbo object.
/* ------------------------------------------------------------------------- */
LLFUNC(GetName, 1, LuaUtilPushVar(lS, AgFbo{lS, 1}().IdentGet()))
/* ========================================================================= **
** ######################################################################### **
** ## Fbo:* member functions structure                                    ## **
** ######################################################################### **
** ------------------------------------------------------------------------- */
LLRSMFBEGIN                            // Fbo:* member functions begin
  LLRSFUNC(Activate),     LLRSFUNC(Blit),           LLRSFUNC(BlitT),
  LLRSFUNC(Destroy),      LLRSFUNC(Finish),         LLRSFUNC(GetFloatCount),
  LLRSFUNC(GetId),        LLRSFUNC(GetLFloatCount), LLRSFUNC(GetMatrix),
  LLRSFUNC(GetName),      LLRSFUNC(IsFinished),     LLRSFUNC(Reserve),
  LLRSFUNC(SetBlend),     LLRSFUNC(SetClear),       LLRSFUNC(SetClearColour),
  LLRSFUNC(SetCRGBA),     LLRSFUNC(SetCX),          LLRSFUNC(SetFilter),
  LLRSFUNC(SetMatrix),    LLRSFUNC(SetTCLTRB),      LLRSFUNC(SetTCLTWH),
  LLRSFUNC(SetTCX),       LLRSFUNC(SetVLTRB),       LLRSFUNC(SetVLTWH),
  LLRSFUNC(SetVLTRBA),    LLRSFUNC(SetVLTWHA),      LLRSFUNC(SetVX),
  LLRSFUNC(SetWireframe),
LLRSEND                                // Fbo:* member functions end
/* ========================================================================= */
// $ Fbo.Main
// < Handle:Fbo=A handle to the main fbo object.
// ? Returns a handle to the main FBO so you can draw to it. Changing the
// ? properties of the main FBO may result in undefined behaviour. Note that
// ? the engine console shares the same FBO so you may want to create a
// ? separatte FBO to draw to.
/* ------------------------------------------------------------------------- */
LLFUNC(Main, 1, LuaUtilClassCreatePtr<Fbo>(lS, *cFbos, &cFboCore->fboMain))
/* ========================================================================= */
// $ Fbo.Create
// > Identifier:string=Reference only user-defined identifier.
// > Width:integer=Width of the FBO.
// > Height:integer=Height of the FBO.
// < Handle:Fbo=A handle to the newly created main fbo object.
// ? Creates a new FBO of the specified size.
/* ------------------------------------------------------------------------- */
LLFUNC(Create, 1,
  const AgNeString aIdentifier{lS, 1};
  const AgTextureDimension aWidth{lS, 2},
                           aHeight{lS, 3};
  AcFbo{lS}().FboInit(aIdentifier, aWidth, aHeight))
/* ========================================================================= */
// $ Fbo.Draw
// ? When the UI mode is set to 3 which is fully manual mode, you need to call
// ? this function for every frame that changes. The main screen FBO will be
// ? flushed and not finished and OpenGL will NOT swap buffers if you do not
// ? call this function.
/* ------------------------------------------------------------------------- */
LLFUNC(Draw, 0, cFboCore->SetDraw())
/* ========================================================================= */
// $ Fbo.IsDrawing
// < State:boolean=Is the main fbo set to redraw?
// ? Returns if the main fbo is set to redraw.
/* ------------------------------------------------------------------------- */
LLFUNC(IsDrawing, 1, LuaUtilPushVar(lS, cFboCore->CanDraw()))
/* ========================================================================= */
// $ Fbo.OnRedraw
// > Func:function=The main redraw function to change to
// ? When OpenGL needs to be reinitialised, the specified callback will be
// ? called so the guest can redraw FBO's and maybe do other stuff. All
// ? texture and fbo data is already preserved so there is no need to
// ? reinitialise any of that, you just need to redraw them.
/* ------------------------------------------------------------------------- */
LLFUNC(OnRedraw, 0, cLua->SetLuaRef(lS, cLua->lrMainRedraw))
/* ========================================================================= */
// $ Fbo.ConSet
// > State:boolean=The console state.
// < Success:boolean=Returns if the requested function was successful.
// ? Shows or hides the console. This does not modify the cvar state. This
// ? function is in Fbo because it only applies to opengl mode. It also
// ? overrides the 'con_disabled' setting.
/* ------------------------------------------------------------------------- */
LLFUNC(ConSet, 1,
  LuaUtilPushVar(lS, cConGraphics->DoSetVisible(AgBoolean{lS, 1})))
/* ========================================================================= */
// $ Fbo.ConHeight
// > State:number=The console height.
// ? Sets the console height normal without modifying the cvar. This function
// ? is in Fbo because it only applies to opengl mode.
/* ------------------------------------------------------------------------- */
LLFUNC(ConHeight, 0, cConGraphics->SetHeight(AgGLfloatLG{lS, 1, 0.0f, 1.0f}))
/* ========================================================================= */
// $ Fbo.ConEnabled
// < State:boolean=The console state.
// ? Returns true if the console is showing, false if it is not. This function
// ? is in Fbo because it only applies to opengl mode.
/* ------------------------------------------------------------------------- */
LLFUNC(ConEnabled, 1, LuaUtilPushVar(lS, cConsole->IsVisible()))
/* ========================================================================= */
// $ Fbo.ConLock
// < State:boolean=The console visibility lock state.
// ? Lock the visibility of the console on or off. This function is in Fbo
// ? because it only applies to opengl mode.
/* ------------------------------------------------------------------------- */
LLFUNC(ConLock, 0, cConGraphics->SetCantDisable(AgBoolean{lS, 1}))
/* ========================================================================= **
** ######################################################################### **
** ## Fbo.* namespace functions structure                                 ## **
** ######################################################################### **
** ------------------------------------------------------------------------- */
LLRSBEGIN                              // Fbo.* namespace functions begin
  LLRSFUNC(ConEnabled), LLRSFUNC(ConHeight), LLRSFUNC(ConLock),
  LLRSFUNC(ConSet),     LLRSFUNC(Create),    LLRSFUNC(Draw),
  LLRSFUNC(IsDrawing),  LLRSFUNC(Main),      LLRSFUNC(OnRedraw),
LLRSEND                                // Fbo.* namespace functions end
/* ========================================================================= **
** ######################################################################### **
** ## Fbo.* namespace constants                                           ## **
** ######################################################################### **
** ========================================================================= */
// @ Fbo.Blends
// < Codes:table=The table of key/value pairs of available flags
// ? Returns the texture filters available. See https://registry.khronos.org/
// ? OpenGL-Refpages/es3/html/glBlendFuncSeparate.xhtml for more information
// ? about the values.
/* ------------------------------------------------------------------------- */
LLRSKTBEGIN(Blends)                    // Beginning of blending types
  LLRSKTITEM(OB_,Z),       LLRSKTITEM(OB_,O),       LLRSKTITEM(OB_,S_C),
  LLRSKTITEM(OB_,O_M_S_C), LLRSKTITEM(OB_,D_C),     LLRSKTITEM(OB_,O_M_D_C),
  LLRSKTITEM(OB_,S_A),     LLRSKTITEM(OB_,O_M_S_A), LLRSKTITEM(OB_,D_A),
  LLRSKTITEM(OB_,O_M_D_A), LLRSKTITEM(OB_,C_C),     LLRSKTITEM(OB_,C_A),
  LLRSKTITEM(OB_,S_A_S),
LLRSKTEND                              // End of blending types
/* ========================================================================= */
// @ Fbo.Filters
// < Codes:table=The table of key/value pairs of available flags
// ? Returns the texture filters available. See https://registry.khronos.org/
// ? OpenGL-Refpages/es3/html/glTexParameter.xhtml for more information about
// ? the values
/* ------------------------------------------------------------------------- */
LLRSKTBEGIN(Filters)                   // Beginning of filter types
  LLRSKTITEM(OF_,N_N),      LLRSKTITEM(OF_,N_L),      LLRSKTITEM(OF_,L_N),
  LLRSKTITEM(OF_,L_L),      LLRSKTITEM(OF_,N_N_MM_N), LLRSKTITEM(OF_,L_N_MM_N),
  LLRSKTITEM(OF_,N_N_MM_L), LLRSKTITEM(OF_,L_N_MM_L), LLRSKTITEM(OF_,N_L_MM_N),
  LLRSKTITEM(OF_,L_L_MM_N), LLRSKTITEM(OF_,N_L_MM_L), LLRSKTITEM(OF_,L_L_MM_L),
LLRSKTEND                              // End of filter types
/* ========================================================================= **
** ######################################################################### **
** ## Fbo.* namespace constants structure                                 ## **
** ######################################################################### **
** ========================================================================= */
LLRSCONSTBEGIN                         // Fbo.* namespace consts begin
  LLRSCONST(Blends), LLRSCONST(Filters),
LLRSCONSTEND                           // Fbo.* namespace consts end
/* ========================================================================= */
}                                      // End of Fbo namespace
/* == EoF =========================================================== EoF == */

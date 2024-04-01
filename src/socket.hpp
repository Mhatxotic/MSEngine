/* == SOCKET.HPP =========================================================== **
** ######################################################################### **
** ## MS-ENGINE              Copyright (c) MS-Design, All Rights Reserved ## **
** ######################################################################### **
** ## Allows multi-threaded network communications using OpenSSL.         ## **
** ######################################################################### **
** ========================================================================= */
#pragma once                           // Only one incursion allowed
/* ------------------------------------------------------------------------- */
namespace ISocket {                    // Start of private module namespace
/* -- Dependencies --------------------------------------------------------- */
using namespace ICert::P;              using namespace IClock::P;
using namespace ICollector::P;         using namespace ICrypt::P;
using namespace ICVar::P;              using namespace ICVarDef::P;
using namespace ICVarLib::P;           using namespace IError::P;
using namespace IEvtMain::P;           using namespace IFlags;
using namespace IIdent::P;             using namespace ILog::P;
using namespace ILuaEvt::P;            using namespace ILuaUtil::P;
using namespace IMemory::P;            using namespace IParser::P;
using namespace IStd::P;               using namespace IString::P;
using namespace ISystem::P;            using namespace ISysUtil::P;
using namespace IThread::P;            using namespace IToken::P;
using namespace IUtil::P;              using namespace IUtf;
using namespace Lib::OS::OpenSSL;
/* ------------------------------------------------------------------------- */
namespace P {                          // Start of public module namespace
/* -- Connection flags ----------------------------------------------------- */
BUILD_SECURE_FLAGS(Socket,
  /* ----------------------------------------------------------------------- */
  // No flags                          Socket is initialising?
  SS_NONE                {0x00000000}, SS_INITIALISING        {0x00000001},
  // Socket is set to use encryption?  Socket is connecting
  SS_ENCRYPTION          {0x00000002}, SS_CONNECTING          {0x00000004},
  // Socket is connected               Socket is sending request (HTTP)
  SS_CONNECTED           {0x00000008}, SS_SENDREQUEST         {0x00000010},
  // Socket waiting for reply? (HTTP)? Socket is downloading (HTTP)
  SS_REPLYWAIT           {0x00000020}, SS_DOWNLOADING         {0x00000040},
  // Socket was closed by server?      Socket was closed by server?
  SS_CLOSEDBYSERVER      {0x00000080}, SS_CLOSEDBYCLIENT      {0x00000100},
  // Socket is disconnecting?          Socket on standby (disconnected)
  SS_DISCONNECTING       {0x00000200}, SS_STANDBY             {0x00000400},
  /* ----------------------------------------------------------------------- */
  // Set if error with event callback? Socket read a packet (not ever set)
  SS_EVENTERROR          {0x40000000}, SS_READPACKET          {0x80000000}
);/* == Socket collector class for collector data and custom variables ===== */
BEGIN_COLLECTOREX(Sockets, Socket, CLHelperUnsafe,
/* -- Internal registry values for http data ------------------------------- **
** We use these key names internally for passing http data around without   **\
** creating unneccesary new variables. Let us keep these key names in       **\
** binary text because it is impossible for the http server to return       **\
** header key names in binary! C++ and LUA can still store keys in binary   **\
** as well so this should be safe! ----------------------------------------- */
const string       strRegVarREQ;       /* Registry key name for req data    */\
const string       strRegVarBODY;      /* " for http body data              */\
const string       strRegVarPROTO;     /* " for http protocol data          */\
const string       strRegVarCODE;      /* " for http status code data       */\
const string       strRegVarMETHOD;    /* " for http method string          */\
const string       strRegVarRESPONSE;  /* HTTP response string              */\
const string       strCipherDefault;   /* Default cipher to use             */\
/* -- Variables ------------------------------------------------------------ */
string_view        strvCipher12;       /* Ciphers for TLSv1.2 from CVar     */\
string_view        strvCipher13;       /* Ciphers for TLSv1.3+ from CVar    */\
string_view        strvUserAgent;      /* User agent string from CVar       */\
SafeInt            iOCSP;              /* Use OCSP (0=Off;1=On;2=Strict)    */\
SafeSizeT          stBufferSize;       /* Default recv/send buffer size     */\
SafeDouble         dRecvTimeout;       /* Receive packet timeout            */\
SafeDouble         dSendTimeout;       /* Send packet timeout               */\
SafeUInt64         qRX;                /* Total bytes received              */\
SafeUInt64         qTX;                /* Total bytes sent                  */\
SafeUInt64         qRXp;               /* Total packets received            */\
SafeUInt64         qTXp;               /* Total packets sent                */\
SafeSizeT          stConnected;,,      /* Total connected sockets           */\
/* -- Derived classes ----------------------------------------------------- */\
public  Certs,                         /* Certificate store                 */\
private LuaEvtMaster<Socket,LuaEvtTypeAsync<Socket>>);
/* == Socket object class ================================================== */
BEGIN_MEMBERCLASS(Sockets, Socket, ICHelperUnsafe),
  /* -- Base classes ------------------------------------------------------- */
  public LuaEvtSlave<Socket,2>,        // Need to store two references
  public Lockable,                     // Lua garbage collector instruction
  public SocketFlags,                  // Socket flags
  public Ident                         // Identifier
{ /* ----------------------------------------------------------------------- */
  struct Packet                        // Connection packet
  { /* --------------------------------------------------------------------- */
    ClkTimePoint   ctpStart;           // Packet timestamp
    Memory         mData;              // Memory block
  };/* --------------------------------------------------------------------- */
  typedef list<Packet> PacketList;     // list of blocks
  /* -- OpenSSL core variables --------------------------------------------- */
  BIO             *bioPtr;             // OpenSSL socket, blank socket
  SSL_CTX         *sslctxPtr;          // OpenSSL context
  SSL             *sslPtr;             // OpenSSL descriptor
  /* -- Statistical variables ---------------------------------------------- */
  SafeUInt64       qRX, qTX,           // Total Transmit/Receive traffic
                   qRXp, qTXp;         // Total Transmit/Receive packets
  /* -- Threads and concurrency -------------------------------------------- */
  Thread           tReader,            // Thread for sockread/http operations
                   tWriter;            // Thread for sockwrite operations
  mutex            mMutex,             // mutex to prevent threading deadlocks
                   mWriter;            // For condition variable
  bool             bUnlock;            // Condition variable unblocker
  condition_variable cvWriter;         // Waiting for write/terminate event
  /* -- Other variables ---------------------------------------------------- */
  unsigned int     uiPort;             // The port number to connect to
  SafeInt          iError,             // Socket error
                   iFd;                // Socket descriptor
  string           strAddr,            // The address in string format
                   strAddrPort,        // The address and port in string format
                   strError,           // Last error string recorded
                   strCipherList,      // Requested cipher list (<=TLSv1.2)
                   strCipherSuite,     // Requested cipher suites (TLSv1.3)
                   strCipher,          // Cipher picked if SSL requested
                   strIP,              // IP address connected to
                   strHost,            // Virtual hostname connected to
                   strRealHost;        // Real hostname connected to
  PacketList       plRX, plTX;         // Transmit/Receive buffers
  size_t           stRX, stTX;         // Total bytes stored in buffers
  Parser<>         pRegistry;          // For storing keypairs
  /* -- Timestamps --------------------------------------------------------- */
  SafeClkDuration  cdConnect,          // Time socket was connecting
                   cdConnected,        // Time socket was connected
                   cdRead,             // Time socket was last read from
                   cdWrite,            // Time socket was last written to
                   cdDisconnect,       // Time socket was disconnecting
                   cdDisconnected;     // Time socket was disconnected
  /* -- Do internal log ---------------------------------------------------- */
  template<typename ...VarArgs>void SocketLog(const LHLevel lhlSeverity,
    const char*const cpFormat, const VarArgs &...vaArgs)
  { // If parameters are specified then cater to them
    if constexpr(sizeof...(VarArgs) > 0)
      cLog->LogExSafe(lhlSeverity, "Socket $:$$$:$ $", CtrGet(), hex,
        FlagGet(), dec, GetAddressAndPort(), StrFormat(cpFormat, vaArgs...));
    // No parameters specified so don't need to format them
    else cLog->LogExSafe(lhlSeverity, "Socket $:$$$:$ $", CtrGet(), hex,
      FlagGet(), dec, GetAddressAndPort(), cpFormat);
  }
  /* -- Internal log ------------------------------------------------------- */
  template<typename ...VarArgs>void SocketLogSafe(const LHLevel lhlSeverity,
    const char*const cpFormat, const VarArgs &...vaArgs)
  { // Return if we don't have this level
    if(cLog->NotHasLevel(lhlSeverity)) return;
    // Synchronise access to socket data while we log details
    const LockGuard lgSocketSync{ mMutex };
    // Write formatted string
    SocketLog(lhlSeverity, cpFormat, vaArgs...);
  }
  /* -- Internal log ------------------------------------------------------- */
  template<typename ...VarArgs>void SocketLogUnsafe(const LHLevel lhlSeverity,
    const char*const cpFormat, const VarArgs &...vaArgs)
  { // Return if we don't have this level
    if(cLog->NotHasLevel(lhlSeverity)) return;
    // Write formatted string
    SocketLog(lhlSeverity, cpFormat, vaArgs...);
  }
  /* -- Initialise static error (no openssl error) ------------------------- */
  int SetErrorStatic(const string &strReason, const bool bSet)
  { // Show reason in log
    SocketLogUnsafe(LH_WARNING, "$", strReason);
    // Forget any error if disconnecting or disconnected
    if(!bSet || IsDisconnectingOrDisconnected()) return -1;
    // Set our own error code
    iError = -1;
    // Set the error as the reason
    strError = StdMove(strReason);
    // Done
    return -1;
  }
  /* -- Set aborted connection --------------------------------------------- */
  int SetAborted(void)
  { // Clear errors
    ERR_clear_error();
    // Connection aborted message
    strError = "Connection aborted";
    // Set our own error code
    iError = -1;
    // Set the error as the reason
    SocketLogSafe(LH_WARNING, "$", strError);
    // Done
    return -1;
  }
  /* -- Socket initial connect failed cleanup function --------------------- */
  int SetError(const string &strReason)
  { // Return if socket was forcefully closed by us
    if(IsDisconnectedByClient()) return -1;
    // Show reason in log
    SocketLogUnsafe(LH_WARNING, "$", strReason);
    // Forget any error if disconnecting or disconnected or error was already
    // set to aborted code?
    if(IsDisconnectingOrDisconnected()) return -1;
    // Clear the error
    strError.clear();
    // Process errors... Only show errors we can actually report on
    iError = CryptGetError(strError);
    SocketLogUnsafe(LH_WARNING, "$", strError);
    if(strError.empty()) strError = strReason;
    // Break loop
    return -1;
  }
  /* -- Read socket -------------------------------------------------------- */
  unsigned int SockRead(char *cpD, const unsigned int uiL)
  { // If thread should exit
    if(tReader.ThreadShouldExit() || tWriter.ThreadShouldExit())
       return static_cast<unsigned int>(SetAborted());
    // Wait for new packet, storing bytes read and compare result
    switch(const unsigned int uiRX = static_cast<unsigned int>
      (BIO_read(bioPtr, cpD, static_cast<int>(uiL))))
    { // Did the server close the conection?
      case 0:
      { // Server closed the connection
        FlagSet(SS_CLOSEDBYSERVER);
        // Return error status, but there is no actual socket error
        return StdMaxUInt;
      } // Did the operation fail? Set error and clean up
      case StdMaxUInt:
        return static_cast<unsigned int>(IsDisconnectedByClient() ?
          SetAborted() : SetErrorSafe("Read error or timeout"));
      // Did openssl fail? Set error and clean up
      case static_cast<unsigned int>(-2):
        return static_cast<unsigned int>(SetErrorSafe("Not implemented"));
      // We read data. Incrememnt counter
      default:
        // Increment received bytes and packet counters
        qRX += uiRX;
        ++qRXp;
        cParent->qRX += uiRX;
        ++cParent->qRXp;
        // Set last received timestamp
        cdRead = cmHiRes.GetEpochTime();
        // Log status
        SocketLogSafe(LH_DEBUG, "$ received", uiRX);
        // Return bytes read
        return uiRX;
    }
  }
  /* -- Write socket ------------------------------------------------------- */
  unsigned int SockWrite(const char *cpD, const unsigned int uiL)
  { // If thread should exit
    if(tReader.ThreadShouldExit() || tWriter.ThreadShouldExit())
      return static_cast<unsigned int>(SetAborted());
    // Wait to write new packet, storing bytes written and compare result
    switch(const unsigned int uiTX = static_cast<unsigned int>
      (BIO_write(bioPtr, cpD, static_cast<int>(uiL))))
    { // Server closed connection. Set connection completed status
      case 0:
      { // Server closed the connection
        FlagSet(SS_CLOSEDBYSERVER);
        // Return no bytes written
        return static_cast<unsigned int>
          (SetErrorStaticSafe("EOF from server"));
      } // Did the operation fail? Disconnect with error
      case StdMaxUInt:
        return static_cast<unsigned int>
          (SetErrorSafe("Send error or timeout"));
      // Other error? Set error and clean up
      case static_cast<unsigned int>(-2):
        return static_cast<unsigned int>
          (SetErrorSafe("Not implemented"));
      // We wrote data.
      default:
        // Make sure we sent the same bytes as read. This should never
        // happen, but if we did?
        if(uiTX == uiL)
        { // Thats good, what we wanted log the transfer
          SocketLogSafe(LH_DEBUG, "$ sent", uiTX);
          // Increment sent bytes and packet counters
          qTX += uiTX;
          ++qTXp;
          cParent->qTX += uiTX;
          ++cParent->qTXp;
          // Set last sent timestamp
          cdWrite = cmHiRes.GetEpochTime();
          // Return bytes written
          return uiTX;
        } // Log the error we did not send enough bytes
        return static_cast<unsigned int>
          (SetErrorSafe(StrFormat("Sent only $/$", uiTX, uiL)));
    }
  }
  /* -- Write string to socket --------------------------------------------- */
  unsigned int SockWrite(const string &strStr)
    { return SockWrite(strStr.data(),
        static_cast<unsigned int>(strStr.length())); }
  /* -- Write memory block class to socket --------------------------------- */
  unsigned int SockWrite(const MemConst &mcSrc)
    { return SockWrite(mcSrc.MemPtr<char>(), mcSrc.MemSize<unsigned int>()); }
  /* -- Convert packet to memblock for LUA API ----------------------------- */
  double GetPacket(Memory &mDest, PacketList &plData, size_t &stS)
  { // Not empty? Return top memory block else through error
    if(plData.empty())
      XC("No packets remaining in blocklist!",
         "Address", strAddr, "Port", uiPort);
    // Get first top packet and move data to memblock supplied by caller
    Packet &pData = plData.front();
    mDest.MemSwap(StdMove(pData.mData));
    // Copy record timestamp
    const ClkTimePoint ctpEnd{ StdMove(pData.ctpStart) };
    // Subtract total bytes counter
    stS -= mDest.MemSize();
    // Pop first RX packet
    plData.pop_front();
    // Return timestamp
    return ClockGetCount<duration<double>>(ctpEnd.time_since_epoch());
  }
  /* -- Packet management -------------------------------------------------- */
  void FlushPackets(PacketList &plList, size_t &stTotal)
    { plList.clear(); stTotal = 0; }
  /* -- Flush all stored packets ------------------------------------------- */
  void FlushPackets(void)
  { // Setup lists we want to flush
    struct PacketListRef { PacketList &plList; size_t &stTotal; };
    typedef array<const PacketListRef, 2> PacketListArray;
    const PacketListArray plaData{ { { plRX, stRX }, { plTX, stTX } } };
    // Flush each list and total value
    for(const PacketListRef &plrItem : plaData)
      FlushPackets(plrItem.plList, plrItem.stTotal);
  }
  /* -- Packet management -------------------------------------------------- */
  void PushData(PacketList &plList, size_t &stTotal, const char*const cpData,
    const size_t stSize)
  { // Insert a new entry into the specified packet list
    plList.push_back({ cmHiRes.GetTime(), { stSize, cpData } });
    // Increase counter for bytes processed
    stTotal += stSize;
  }
  /* -- Send raw data ------------------------------------------------------ */
  void Send(const char *cpData, const size_t stSize)
  { // Bail if not connected
    if(!IsConnected())
      XC("Send on unconnected socket!", "Address", strAddr, "Port", uiPort);
    // Add buffer to queue
    PushData(plTX, stTX, cpData, stSize);
    // Unblock writer thread
    WriteUnblock();
  }
  /* -- Send data as other types ------------------------------------------- */
  void Send(const MemConst &mcPacket)
    { Send(mcPacket.MemPtr<char>(), mcPacket.MemSize()); }
  void SendString(const string &strData)
    { Send(strData.data(), strData.length()); }
  /* ----------------------------------------------------------------------- */
  void SetAddress(const string &strA, const unsigned int &uiP)
  { // Check parameters
    if(strA.empty())
      XC("Address not specified!", "Port", uiP);
    if(!ValidAddress(strA))
      XC("Address invalid!", "Address", strA, "Port", uiP);
    if(!uiP || uiP > 65535)
      XC("Port invalid!", "Address", strA, "Port", uiP);
    // OK set address and port
    strAddr = strA;
    uiPort = uiP;
    strAddrPort = StrAppend(strA, ':', uiP);
    // Clear previous names if re-using class
    strRealHost.clear();
    strIP.clear();
  }
  /* -- Disconnect the socket ---------------------------------------------- */
  void FinishDisconnect(void)
  { // Lock mutex to prevent data race
    const LockGuard lgSocketSync{ mMutex };
    { // Have BIO socket pointer?
      if(bioPtr)
      { // This automatically frees the SSL context
        BIO_free_all(bioPtr);
        // Clear addresses
        bioPtr = nullptr;
        sslPtr = nullptr;
      } // Have SSL pointer? If for some reason we have it and not a bio
      else if(sslPtr)
      { // Shutdown and free the SSL context
        SSL_shutdown(sslPtr);
        SSL_free(sslPtr);
        sslPtr = nullptr;
      } // Clear context if created
      if(sslctxPtr) { SSL_CTX_free(sslctxPtr); sslctxPtr = nullptr; }
    } // Don't log if we're already disconnected
    if(IsDisconnected()) return;
    // Set standby status
    AddStatus(SS_STANDBY, cdDisconnected);
    // Return if socket was never connected
    if(FlagIsClear(SS_CONNECTED)) return;
    // Decrement connection count
    --cParent->stConnected;
    // Report disconnection and statistics to log
    SocketLogUnsafe(LH_DEBUG, "Disconnected (RX:$/$;TX:$/$).",
      GetRXpkt(), GetRX(), GetTXpkt(), GetTX());
  }
  /* -- Compact all packets into single packet ----------------------------- */
  void Compact(Memory &mDest, PacketList &plData, size_t &stX)
  { // Bail if no packets, but 0 bytes will still be allocated
    if(plData.empty()) { mDest.MemInitBlank(); return; }
    // If zero size just flush all the empty packets and return
    if(!stX) { mDest.MemInitBlank(); return FlushPackets(plData, stX); }
    // Resize memblock to hold all data
    mDest.MemInitBlank(stX);
    // Size of buffers is now zero
    stX = 0;
    // Byte offset counter
    size_t stOffset = 0;
    // Loop until...
    do
    { // Get packet memory block and copy it into our destination memory block
      const MemConst &mcPacket = plData.front().mData;
      mDest.MemWriteBlock(stOffset, mcPacket);
      // Increment counter
      stOffset += mcPacket.MemSize();
      // Pop packet
      plData.pop_front();
    } // ...list is fully emptied
    while(!plData.empty());
  }
  /* -- Create connection with select used to monitor for timeout ---------- */
  int DoConnect(void)
  { // Set hostname (always returns 1).
    if(CryptBIOSetConnHostname(bioPtr, GetAddressAndPort().c_str()) != 1)
      return SetErrorSafe("Resolve failed");
    // Log and do secure connection
    SocketLogSafe(LH_DEBUG, "$onnecting...", IsSecure() ? "Securely c" : "C");
    // Set connecting flag. Do send an event for this
    AddStatus(SS_CONNECTING, cdConnect);
    // Abort if requested
    if(tReader.ThreadShouldExit()) return SetAborted();
    // Try to connect and if failed?
    if(BIO_do_connect(bioPtr) != 1) return SetErrorSafe("Connect failed");
    // Abort if requested
    if(tReader.ThreadShouldExit()) return SetAborted();
    // Set descriptor and set error if failed
    if(!UpdateDescriptor()) return SetErrorSafe("Lost descriptor");
    // Get and check pointer to address data
    if(const BIO_ADDR*const baData = CryptBIOGetConnAddress(bioPtr))
    { // Setup query commands for host and IP data
      struct AddressData{ const int iId; string &strDest; };
      typedef array<const AddressData, 2> AddressDataArray;
      const AddressDataArray adaCmds{ { { 1, strIP }, { 0, strRealHost } } };
      // Enumerate and store the address data
      for(const AddressData &adCmd : adaCmds)
      { // Thanks to OpenSSL not giving us a unique_ptr compatible deallocator,
        // we need to do this ugly code to auto free the allocated the address.
        // I don't know how to make OPENSSL_free work with unique_ptr!
        struct AddrPtr{ const char*const cpPtr;
          AddrPtr(const BIO_ADDR*const baD, const int iId) :
            cpPtr(BIO_ADDR_hostname_string(baD, iId)) { }
          ~AddrPtr(void)
            { if(cpPtr) OPENSSL_free(UtfToNonConstCast<void*>(cpPtr)); }
          operator bool(void) const { return cpPtr != nullptr; }
        };
        // Get item of interest and if successful, move the result into the
        // specified destination
        if(const AddrPtr apAddr{ baData, adCmd.iId })
          UtilMoveVarSafe(mMutex, adCmd.strDest, apAddr.cpPtr);
      }
    } // No IP address detected for some reason
    else return SetErrorSafe("No address found");
    // Show connected ip address
    SocketLogSafe(LH_DEBUG, "Connected to $", GetIPAddress());
    // Set socket read and send timeout
    switch(cSystem->SetSocketTimeout(iFd,
      cParent->dRecvTimeout, cParent->dSendTimeout))
    { // Success
      case 0: break;
      // Failed so just log message
      case 1:
        SocketLogSafe(LH_WARNING, "Set recv timeout failed");
        break;
      case 2:
        SocketLogSafe(LH_WARNING, "Set send timeout failed");
        break;
      case 3:
        SocketLogSafe(LH_WARNING, "Set recv/send timeout failed");
        break;
      default:
        SocketLogSafe(LH_WARNING, "Unknown error setting socket timeouts");
        break;
    } // Until thread says to terminate
    if(tReader.ThreadShouldExit()) return SetAborted();
    // Return success if the handshake succeeded or process error
    return BIO_do_handshake(bioPtr) == 1 ?
      0 : SetErrorSafe("Handshake failed");
  }
  /* -- OCSP verification result ------------------------------------------- */
  int OCSPVerificationResponse(SSL*const sslCbPtr)
  { // Allocate memory for response and get size of response. We actually need
    // the response to not be nullptr too or there is no response
    const unsigned char *cpResp = nullptr;
    const long lLength = SSL_get_tlsext_status_ocsp_resp(sslCbPtr, &cpResp);
    if(lLength != -1 && UtfIsCStringValid(cpResp))
    { // Got a response so make sure it is freed on leaving the scope
      typedef unique_ptr<ocsp_response_st,
        function<decltype(OCSP_RESPONSE_free)>> OcspResponsePtr;
      if(OcspResponsePtr orpResp{ d2i_OCSP_RESPONSE(nullptr, &cpResp,
        lLength), OCSP_RESPONSE_free })
          return 1;
      // Failed to parse response
      SocketLogSafe(LH_WARNING, "OCSP response parse failure");
      // Return result from response call
      return 0;
    } // No response but connection may continue
    SocketLogSafe(LH_DEBUG, "No OCSP response");
    // The callback when used on the client side should return a negative value
    // on error; 0 if the response is not acceptable (in which case the
    // handshake will fail) or a positive value if it is acceptable.
    return cParent->iOCSP >= 2 ? 0 : 1;
  }
  /* -- Socket initial connect function ------------------------------------ */
  int InitialConnect(void)
  { // Initialise the status flags
    FlagReset(SS_INITIALISING);
    // Reset counters and timers
    qRX = qTX = qRXp = qTXp = 0;
    cdConnect = cdConnected = cdRead = cdWrite = cdDisconnect =
      cdDisconnected = seconds{0};
    // Flush packets in all buffers
    FlushPackets();
    // If want TLS encryption?
    if(!strCipherSuite.empty() || !strCipherList.empty())
    { // Set encryption flag. Do not send a LUA event for this
      FlagSet(SS_ENCRYPTION);
      // Setup new TLS client context
      sslctxPtr = SSL_CTX_new(TLS_client_method());
      if(!sslctxPtr) return SetErrorSafe("Init TLS failed");
      // Set cipher options
      if(!strCipherSuite.empty())
        if(!SSL_CTX_set_ciphersuites(sslctxPtr, strCipherSuite.c_str()))
          return SetErrorStaticSafe("Invalid cipher suite");
      // Set ciphers supported, and if failed? Just show warning
      if(!strCipherList.empty())
        if(!SSL_CTX_set_cipher_list(sslctxPtr, strCipherList.c_str()))
          return SetErrorStaticSafe("Invalid cipher list");
      // Set context to release buffers as we don't reuse the contexts
      SSL_CTX_set_mode(sslctxPtr, SSL_MODE_RELEASE_BUFFERS);
      // Set our shared certificate store if we have one
      if(cParent->CertsIsStoreAvailable() &&
        !CryptSSLCtxSet1VerifyCertStore(sslctxPtr, cParent->CertsGetStore()))
          return SetErrorStaticSafe("Cert store failure");
      // Setup verification, make a new verification context and if succeded?
      typedef unique_ptr<X509_VERIFY_PARAM,
        function<decltype(X509_VERIFY_PARAM_free)>> X509VerifyParamPtr;
      if(X509VerifyParamPtr x509vp{ X509_VERIFY_PARAM_new(),
        X509_VERIFY_PARAM_free })
      { // Set flags
        // * Check all ceritificates against CRL.
        // * Strict X509 certificate formats.
        // * Check root CA (self-signed) certificates.
        if(X509_VERIFY_PARAM_set_flags(x509vp.get(), X509_V_FLAG_CRL_CHECK_ALL
          | X509_V_FLAG_X509_STRICT | X509_V_FLAG_CHECK_SS_SIGNATURE))
        { // Always check subject line in certificate
          X509_VERIFY_PARAM_set_hostflags(x509vp.get(),
            X509_CHECK_FLAG_ALWAYS_CHECK_SUBJECT);
          // Want good encryption
          X509_VERIFY_PARAM_set_auth_level(x509vp.get(), 0);
          // Our certificate chain is full of server CA certificates
          if(X509_VERIFY_PARAM_set_purpose(x509vp.get(),
            X509_PURPOSE_SSL_SERVER))
          { // Ceritificate must match this domain
            if(X509_VERIFY_PARAM_set1_host(x509vp.get(), strAddr.data(),
              strAddr.length()))
            { // Apply to context and return success
              if(!SSL_CTX_set1_param(sslctxPtr, x509vp.get()))
              { // Log the error and return failure
                SocketLogSafe(LH_WARNING,
                  "Failed to assign verification parameters to context");
                return -1;
              } // Succeeded a this point
            } // Failed setting host?
            else
            { // Log the error and return failure
              SocketLogSafe(LH_WARNING, "Failed to set matching hostname");
              return -1;
            }
          } // Failed setting purpose?
          else
          { // Log the error and return failure
            SocketLogSafe(LH_WARNING, "Failed to set purpose");
            return -1;
          }
        } // Failed setting verification flags?
        else
        { // Log the error and return failure
          SocketLogSafe(LH_WARNING, "Failed to set verification flags");
          return -1;
        }
      } // Failed creating context?
      else
      { // Log the error and return failure
        SocketLogSafe(LH_WARNING, "Failed to create verification context");
        return -1;
      } // Done setting up verification. Now create socket
      bioPtr = BIO_new_ssl_connect(sslctxPtr);
      if(!bioPtr) return SetErrorSafe("Failed to create BIO socket");
      // Try to get ssl pointer from socket
      if(CryptBIOGetSSL(bioPtr, &sslPtr) < 1)
        return SetErrorSafe("No SSL ptr from BIO");
      if(!sslPtr) return SetErrorSafe("Get SSL ptr failed");
      // Client mode
      BIO_set_ssl_mode(bioPtr, 1);
      // OCSP verification option enabled?
      if(cParent->iOCSP >= 1)
      { // Setup OCSP verification
        if(!SSL_set_tlsext_status_type(sslPtr, TLSEXT_STATUSTYPE_ocsp))
          SocketLogSafe(LH_WARNING, "Failed to setup OCSP verification!");
        // Set callback and argument
        int(*fCB)(SSL*,void*) = [](SSL*const sO, void*const vpS)->int
          { return reinterpret_cast<Socket*>(vpS)->
              OCSPVerificationResponse(sO); };
        if(!CryptSSLCtxSetTlsExtStatusCb(sslctxPtr, fCB))
          SocketLogSafe(LH_WARNING,
            "Failed to setup OCSP verification callback!");
        if(!SSL_CTX_set_tlsext_status_arg(sslctxPtr,
          reinterpret_cast<void*>(this)))
            SocketLogSafe(LH_WARNING,
              "Failed to setup OCSP verification argument!");
      } // Set SNI hostname. Some sites break if this is not set
      if(!CryptSSLSetTlsExtHostName(sslPtr, strAddr.c_str()))
        return SetErrorStaticSafe("Init TLS SNI hostname failed");
      // Log and do secure connection
      if(DoConnect() == -1) return -1;
      // Get X509 chain verificiation result
      switch(const size_t stRes =
        static_cast<size_t>(SSL_get_verify_result(sslPtr)))
      { // No error? Log success and carry on
        case X509_V_OK: SocketLogSafe(LH_DEBUG, "X509 chain is good"); break;
        // Anything else?
        default:
        { // Find error code if the error code information is not found?
          const auto xErrInfoIt{ cParent->CertsGetError(stRes) };
          if(cParent->CertsIsNotErrorValid(xErrInfoIt))
          { // Return success if user wants to bypass it
            if(cParent->CertsIsNotX509BypassFlagSet(1, 0x8000000000000000ULL))
            { // Set error and return status
              SetErrorStaticSafe(StrAppend("X509_V_ERR_UNKNOWN_", stRes));
              return -1;
            } // Log the warning and return success
            SocketLogSafe(LH_WARNING, "Unknown X509 error $ bypassed!", stRes);
          } // Found the error code
          else
          { // Get reference to structure
            const auto &xErrInfo = xErrInfoIt->second;
            // Build error code
            const string strErr{ StrAppend("X509_V_ERR_", xErrInfo.cpErr) };
            // Return success if user wants to bypass it
            if(cParent->CertsIsNotX509BypassFlagSet(
                 xErrInfo.stBank, xErrInfo.qFlag))
            { // Set error and return status
              SetErrorStaticSafe(strErr);
              return -1;
            } // Log the warning and return success
            SocketLogSafe(LH_WARNING, "$ bypassed!", strErr);
            // Set socket error and error string
          } // Done
          break;
        }
      } // Get cipher and if we got it?
      string strD; strD.resize(128);
      if(SSL_CIPHER_description(SSL_get_current_cipher(sslPtr),
        const_cast<char*>(strD.data()), static_cast<int>(strD.length())))
      { // Remove carriage return
        strD.resize(strlen(strD.c_str()) - 1);
        // Set cipher used
        UtilMoveVarSafe(mMutex, strCipher, strD);
        // Print encryption info
        SocketLogUnsafe(LH_DEBUG, "Cipher is $", strCipher);
      } // Get cipher failed? Log failure
      else SocketLogSafe(LH_WARNING, "Failed $", strD.length());
      // Get server certificate
      if(X509*const xCert = SSL_get0_peer_certificate(sslPtr))
      { // Get certificate subject and if successful?
        if(X509_NAME_oneline(X509_get_subject_name(xCert),
          const_cast<char *>(strD.data()), static_cast<int>(strD.length())))
        { // Log the subject line of the certificate
          SocketLogSafe(LH_DEBUG, "Subject is $", strD);
        } // Get certificate issuer and if successful?
        if(X509_NAME_oneline(X509_get_issuer_name(xCert),
          const_cast<char *>(strD.data()), static_cast<int>(strD.length())))
        { // Log the issuer line of the certificate
          SocketLogSafe(LH_DEBUG, "Issuer is $", strD);
        } // Don't free certificate (using get0)
      } // Error occured
      else return SetErrorSafe("Server returned no certificate");
    } // No security
    else
    { // Create socket and bail out if failed
      bioPtr = BIO_new(BIO_s_connect());
      if(!bioPtr) return SetErrorSafe("Failed to create BIO socket");
      // Log and do insecure connection
      if(DoConnect() == -1) return -1;
    } // Now connected
    AddStatus(SS_CONNECTED, cdConnected);
    // Increase connected count
    ++cParent->stConnected;
    // Successful connect
    return 0;
  }
  /* -- Writer thread notification ----------------------------------------- */
  void WriteUnblock(void)
  { // Acquire unique lock
    const UniqueLock ulSocketGuard{ mWriter };
    // Unblock variable
    bUnlock = true;
    // Notify the condition variable
    cvWriter.notify_one();
  }
  /* -- Get and delete registry item --------------------------------------- */
  const string GetRegistry(const string &strItem)
  { // Find item and if we didn't find it? Return default string
    const StrNCStrMapIt sncsmiIt{ pRegistry.find(strItem) };
    if(sncsmiIt == pRegistry.cend()) return {};
    // Get the value and delete it. We will move instead of copying
    const string strReq{ StdMove(sncsmiIt->second) };
    pRegistry.erase(sncsmiIt);
    return strReq;
  }
  /* -- String is binary? Returns location of binary ----------------------- */
  bool ValidHeaderPacket(const string &strStr)
  { // For each character in response, if the character is valid printable
    // ASCII character then goto next
    return !any_of(strStr.cbegin(), strStr.cend(), [](const unsigned char &ucC)
      { return ucC < ' ' && ucC != '\r' && ucC != '\n'; });
  }
  /* -- HTTP Socket main thread function ----------------------------------- */
  int HTTPMain(void)
  { // Connect and send http request and break loop if failed.
    if(InitialConnect() == -1) return 1;
    // Check if this is a HEAD request
    const bool bIsHead = GetRegistry(cParent->strRegVarMETHOD) == "HEAD";
    // Set sending request status event
    AddStatus(SS_SENDREQUEST);
    { // Get first line request and body which will also be deleted from the
      // map leaving only the list of headers that are to be sent. Careful when
      // trying to optimise/one-line this as MSVC compiler WILL evaluate
      // expressions in the opposite direction.
      const string
        strReq{ StdMove(GetRegistry(cParent->strRegVarREQ)) },
        strBody{ StdMove(GetRegistry(cParent->strRegVarBODY)) },
        strHdrs{ StdMove(pRegistry.ParserImplodeEx(": ", cCommon->CrLf())) },
        strPkt{ StdMove(StrAppend(strReq,
          strHdrs, cCommon->CrLf(), strBody)) };
      // Write the full request to the server and return if failed
      if(SockWrite(strPkt) == StdMaxUInt) return -1;
    } // Set sent request status event
    AddStatus(SS_REPLYWAIT);
    // Content read and content-length
    size_t stContentRead = 0, stContentLength = 0;
    // Response headers
    string strHeaders;
    // Allocate memory for read buffer
    Memory mDest{ cParent->stBufferSize };
    // Expecting reponse headers? and connection closed status
    bool bHeaders = true;
    // Begin monitoring for reply and break if thread should exit
    while(tReader.ThreadShouldNotExit())
    { // Wait for data from connected server
      const unsigned int uiBX =
        SockRead(mDest.MemPtr<char>(), mDest.MemSize<unsigned int>());
      // Connection error or server closed connection?
      if(uiBX == StdMaxUInt)
      { // If we were waiting for headers still?
        if(bHeaders) return SetErrorSafe("Response failed");
        // We were downloading so if there was a content length?
        if(stContentLength)
        { // Read the correct number of bytes? Or we're just doing a HEAD req?
          // Log that the download was successful.
          if(stContentRead == stContentLength || bIsHead)
            SocketLogSafe(LH_DEBUG, "Download successful");
          // We did not get the correct number of bytes? Set error code.
          else return SetErrorSafe(StrAppend("Failed at ", stContentRead));
        } // There was no content length? Just log the bytes downloaded
        else SocketLogSafe(LH_DEBUG, "$ downloaded", stContentRead);
        // We're done with the connection
        return 1;
      } // Not processing headers?
      if(!bHeaders)
      { // Not processing headers? Processing content? Increment content read
        stContentRead += uiBX;
        // Push data into RX list. Truncate bytes read if we have a content
        // length and the we read past the content length.
        PushDataSafe(plRX, stRX, mDest.MemPtr<char>(),
          stContentLength && stContentRead > stContentLength ?
            uiBX - static_cast<unsigned int>(stContentLength - stContentRead) :
            uiBX);
        // Have content length and at EOF? Done!
        if(stContentLength && stContentRead == stContentLength)
        { // Log it and return success
          SocketLogSafe(LH_DEBUG, "Download complete");
          return 1;
        } // Wait for next packet, thread abort or server disconnect.
        continue;
      } // Make string from response. There could be binary characters in this
      // but it does not matter
      string strResp{ mDest.MemPtr<char>(), uiBX };
      // Find end of headers marker and if we do not have it yet?
      const size_t stEnd = strResp.find(cCommon->CrLf2());
      if(stEnd == string::npos)
      { // Check for binary data and if we found binary data? Bail out!
        if(!ValidHeaderPacket(strResp))
          return SetErrorStaticSafe("Binary code in headers");
        // Add to full headers string
        strHeaders += strResp;
        // Wait for next packet
        continue;
      } // Ok we got the headers. Collect data.
      bHeaders = false;
      // Get cut off point between headers to data and if we got it?
      const size_t stInitial = strResp.length() - (stEnd + 4);
      if(stInitial > 0)
      { // Push data into RX list
        PushDataSafe(plRX, stRX, mDest.MemRead(stEnd+4), stInitial);
        // Increment content read
        stContentRead += stInitial;
        // Truncate extra bytes
        strResp.resize(stEnd);
      } // Check for binary code in the last packet returned? Bail out!
      if(!ValidHeaderPacket(strResp))
        return SetErrorStaticSafe("Binary code in headers");
      // Add rest of response to headers
      strHeaders += strResp;
      // Build output headers list by exploding header string
      pRegistry.ParserReInit(strHeaders, cCommon->CrLf(), ':');
      if(pRegistry.empty()) return SetErrorStaticSafe("No response");
      // Done with the headers string
      strHeaders.clear();
      strHeaders.shrink_to_fit();
      // Find initial reponse (should be #0 set by VARS class)
      const StrNCStrMapConstIt
        vlR{ pRegistry.find(cParent->strRegVarRESPONSE) };
      if(vlR == pRegistry.cend()) return SetErrorStaticSafe("Bad response");
      // Split into words. We should have got at least three words
      const Token tWords{ vlR->second, cCommon->Space() };
      if(tWords.size() < 3) return SetErrorStaticSafe("Unknown response");
      // Get protocol and if it is not valid?
      const string strProtoRecv{ tWords.front() };
      if(strProtoRecv != "HTTP/1.0" && strProtoRecv != "HTTP/1.1")
        return SetErrorStaticSafe(StrFormat("Bad protocol '$'", strProtoRecv));
      // Get http status code string and if not a valid number?
      const string strStatus{ tWords[1] };
      if(!StrIsInt(strStatus))
        return SetErrorStaticSafe(StrFormat("Bad status '$'", strStatus));
      // Convert to integer and if valid?
      const size_t stStatus = StrToNum<size_t>(strStatus);
      if(stStatus < 100 || stStatus > 999)
        return SetErrorStaticSafe(StrAppend("Bad status code ", strStatus));
      // If the status code is anything but an error? Log successful code
      if(stStatus < 400) SocketLogSafe(LH_DEBUG, "Status code $", strStatus);
      // Error status code? Log error status code
      else SocketLogSafe(LH_WARNING, "Status error $", strStatus);
      // Add protocol and status code to registry so guest can read them
      // without having to perform any special string operations
      pRegistry.ParserPushOrUpdatePair(cParent->strRegVarPROTO, strProtoRecv);
      pRegistry.ParserPushOrUpdatePair(cParent->strRegVarCODE, strStatus);
      // For each response var. Push key/value pair to TX registry
      for(const auto &vlI : pRegistry)
        PushTXPairSafe(vlI.first, vlI.second);
      // If we got a content type?
      const StrNCStrMapConstIt sncsmciType{ pRegistry.find("content-type") };
      if(sncsmciType != pRegistry.cend())
        SocketLogSafe(LH_DEBUG, "Type is $", sncsmciType->second);
      // Should get content length
      const StrNCStrMapConstIt sncsmciLen{ pRegistry.find("content-length") };
      if(sncsmciLen != pRegistry.cend())
      { // Get reference to string and if it's not valid?
        const string &strVal = sncsmciLen->second;
        if(!StrIsInt(strVal))
        { // Assume zero, safe to continue and log the warning
          stContentLength = 0;
          SocketLogSafe(LH_WARNING, "Invalid content length");
        } // Valid content-length
        else
        { // Convert length string to integer and log the length
          stContentLength = StrToNum<size_t>(strVal);
          SocketLogSafe(LH_DEBUG, "Length is $", stContentLength);
        } // Set downloading status
        AddStatus(SS_DOWNLOADING);
        // If we already got enough bytes from the header packet?
        if(stInitial == stContentLength)
        { // Log it and return success
          SocketLogSafe(LH_DEBUG, "Downloaded in one go");
          return 1;
        } // If we got too many bytes? treat it as completed anyway
        if(stInitial > stContentLength)
        { // Log it and return success
          SocketLogSafe(LH_DEBUG, "Downloaded ($ excess)",
            stInitial-stContentLength);
          return 1;
        } // Haven't received all the data
      } // No content length and connection not closed
      else
      { // Set zero content length and downloading flag
        stContentLength = 0;
        AddStatus(SS_DOWNLOADING);
      } // Wait for next packet, thread abort or server disconnect
    } // Got here because the thread was aborted
    return SetAborted();
  }
  /* -- Socket http connection --------------------------------------------- */
  int SocketHTTPThreadMain(Thread &)
  { // Return code
    int iReturn;
    // Capture exceptions and switch to thiscall
    try { iReturn = HTTPMain(); }
    // exception occured?
    catch(const exception &E)
    { // Report error
      cLog->LogErrorExSafe("(SOCKET HTTP THREAD EXCEPTION) $", E.what());
      // Set error message
      iReturn = SetErrorStaticSafe(E.what());
    } // Send disconnection and clear
    SendDisconnect();
    FinishDisconnect();
    // Required to stop memory leak
    OPENSSL_thread_stop();
    // Return status
    return iReturn;
  }
  /* -- Return if there are TX packets available --------------------------- */
  bool IsTXPacketAvailable(void)
    { const LockGuard lgSocketSync{ mMutex }; return !plTX.empty(); }
  /* -- Get memory to oldest TX packet ------------------------------------- */
  const MemConst &GetOldestTXPacketSafe(void)
    { const LockGuard lgSocketSync{ mMutex }; return plTX.front().mData; }
  /* -- Pop oldest TX packet ----------------------------------------------- */
  void PopOldestTXPacketSafe(void)
    { const LockGuard lgSocketSync{ mMutex }; return plTX.pop_front(); }
  /* -- Socket write manager ----------------------------------------------- */
  int SockWriteManager(void)
  { // Block until requested to exit
    while(tWriter.ThreadShouldNotExit())
    { // For each packet waiting to be written
      while(IsTXPacketAvailable())
      { // Get oldest available TX packet, send it, and kill thread on error
        const MemConst &mcPacket = GetOldestTXPacketSafe();
        if(SockWrite(mcPacket) == StdMaxUInt) return 2;
        // Subtract total bytes counter and pop the packet we just sent
        stTX -= mcPacket.MemSize();
        PopOldestTXPacketSafe();
      } // Setup lock for condition variable and wait for new data to write
      UniqueLock uLock{ mWriter };
      cvWriter.wait(uLock,
        [this]{ return bUnlock || tReader.ThreadShouldExit(); });
      // Next wait will block
      bUnlock = false;
    } // Sucesss
    return 1;
  }
  /* -- Socket write thread ------------------------------------------------ */
  int SockWriteThreadMain(Thread &)
  { // Return code
    int iReturn;
    // Capture exceptions and execute the manager
    try { iReturn = SockWriteManager(); }
    // exception occured?
    catch(const exception &E)
    { // Report error
      cLog->LogErrorExSafe("(SOCKET WRITE THREAD EXCEPTION) $", E.what());
      // Set error message
      iReturn = SetErrorStaticSafe(E.what());
    } // Force close the socket if the reader thread isn't already exiting
    SendDisconnect();
    // Required to stop memory leak
    OPENSSL_thread_stop();
    // Return exit code
    return iReturn;
  }
  /* -- Dispatch an event -------------------------------------------------- */
  void DispatchEvent(const SocketFlagsConst &evtId)
  { // Signal events handler to execute event callback on the next frame.
    // Add the event to the event store so we can remove the event when the
    // destructor is called before the event is called.
    LuaEvtDispatch(evtId.FlagGet());
  }
  /* -- Socket read manager ------------------------------------------------ */
  int SockReadManager(void)
  { // Create a thread to write data requests
    tWriter.ThreadInit(StrAppend("SW:", GetAddressAndPort()),
      bind(&Socket::SockWriteThreadMain, this, _1), this);
    // Try to connect and if it didn't fail kill the thread
    if(InitialConnect() == -1) return 2;
    // Create read transfer buffer
    Memory mDest{ cParent->stBufferSize };
    // Loop until thread should terminate
    while(tReader.ThreadShouldNotExit())
    { // Wait for new data to be read and kill thread on error
      const unsigned int uiBX =
        SockRead(mDest.MemPtr<char>(), mDest.MemSize<unsigned int>());
      if(uiBX == StdMaxUInt) return 3;
      // Push data block into list ready for LUA to collect
      PushDataSafe(plRX, stRX, mDest.MemPtr<char>(),
        static_cast<size_t>(uiBX));
      // Send read event
      DispatchEvent(SS_READPACKET);
    } // Thread should terminate
    return 1;
  }
  /* -- Socket read thread ------------------------------------------------- */
  int SockReadThreadMain(Thread &)
  { // Return code
    int iReturn;
    // Capture exceptions
    try { iReturn = SockReadManager(); }
    // exception occured?
    catch(const exception &E)
    { // Report error
      cLog->LogErrorExSafe("(SOCKET THREAD EXCEPTION) $", E.what());
      // Set error message
      iReturn = SetErrorStaticSafe(E.what());
    } // Have writer thread?
    if(tWriter.ThreadIsNotCurrent() && tWriter.ThreadIsRunning())
    { // Call for writer thread to terminate
      tWriter.ThreadSetExit();
      // Unblock writer thread so that it may terminate cleanly
      WriteUnblock();
      // Wait for thread to terminate and deinit
      tWriter.ThreadStop();
      tWriter.ThreadDeInit();
    } // Clear connection and clean-up
    SendDisconnect();
    FinishDisconnect();
    // Required to stop memory leak
    OPENSSL_thread_stop();
    // Break thread
    return iReturn;
  }
  /* -- Error occured in event so start cleaning up ------------------------ */
  void EventError(void)
  { // Add error flag
    FlagSet(SS_EVENTERROR);
    // Disconnect the socket and clean up
    SendDisconnectAndWait();
    // Clear the references and state so no more exceptions/events occur
    LuaEvtDeInit();
  }
  /* -- Update file descriptor --------------------------------------------- */
  bool UpdateDescriptor(void)
  { // Update descriptor
    iFd = CryptBIOGetFd(bioPtr);
    // Return if succeeded
    return iFd != -1;
  }
  /* ----------------------------------------------------------------------- */
  const string &GetAddressAndPort(void) const { return strAddrPort; }
  const string GetIPAddressAndPort(void) const
    { return StrAppend(GetIPAddress(), ':', GetPort()); }
  const string &GetErrorStr(void) const { return strError; }
  /* ----------------------------------------------------------------------- */
  template<typename AnyType>const AnyType GetVarSafe(const AnyType &atVar)
    { const LockGuard lgSocketSync{ mMutex }; return atVar; }
  /* ----------------------------------------------------------------------- */
  size_t GetXQCountSafe(const PacketList &plList)
    { const LockGuard lgSocketSync{ mMutex };
      return plList.size(); }
  double GetPacketXSafe(Memory &mbD, PacketList &plList, size_t &stX)
    { const LockGuard lgSocketSync{ mMutex };
      return GetPacket(mbD, plList, stX); }
  void CompactXSafe(Memory &mbD, PacketList &plList, size_t &stX)
    { const LockGuard lgSocketSync{ mMutex };
      Compact(mbD, plList, stX); }
  /* -- Events status ------------------------------------------------------ */
  bool IsConnected(void) const { return FlagIsSet(SS_CONNECTED); }
  bool IsDisconnected(void) const { return FlagIsSet(SS_STANDBY); }
  bool IsDisconnecting(void) const { return FlagIsSet(SS_DISCONNECTING); }
  bool IsDisconnectingOrDisconnected(void) const
    { return IsDisconnecting() || IsDisconnected(); }
  bool IsDisconnectedByClient(void) { return FlagIsSet(SS_CLOSEDBYCLIENT); }
  /* --------------------------------------------------------------- */ public:
  bool IsSecure(void) const { return FlagIsSet(SS_ENCRYPTION); }
  int GetFD(void) const { return iFd; }
  int GetError(void) const { return iError; }
  /* -- Connection data ---------------------------------------------------- */
  const string &GetAddress(void) const { return strAddr; }
  const string GetAddressSafe(void) { return GetVarSafe(GetAddress()); }
  const unsigned int &GetPort(void) const { return uiPort; }
  unsigned int GetPortSafe(void) { return GetVarSafe(GetPort()); }
  const string &GetIPAddress(void) const { return strIP; }
  const string GetIPAddressSafe(void) { return GetVarSafe(GetIPAddress()); }
  const string GetAddressAndPortSafe(void)
    { return GetVarSafe(GetAddressAndPort()); }
  const string GetIPAddressAndPortSafe(void)
    { return GetVarSafe(GetIPAddressAndPort()); }
  const string &GetRealHost(void) const { return strRealHost; }
  const string GetRealHostSafe(void) { return GetVarSafe(GetRealHost()); }
  const string &GetCipher(void) const { return strCipher; }
  const string GetCipherSafe(void) { return GetVarSafe(GetCipher()); }
  const string GetErrorStrSafe(void) { return GetVarSafe(GetErrorStr()); }
  /* -- RX packets --------------------------------------------------------- */
  uint64_t GetRX(void) const { return qRX; }
  uint64_t GetRXpkt(void) const { return qRXp; }
  size_t GetRXQCount(void) const { return plRX.size(); }
  size_t GetRXQCountSafe(void) { return GetXQCountSafe(plRX); }
  double GetPacketRXSafe(Memory &mbD)
    { return GetPacketXSafe(mbD, plRX, stRX); }
  void CompactRXSafe(Memory &mbD) { CompactXSafe(mbD, plRX, stRX); }
  /* -- TX packets --------------------------------------------------------- */
  uint64_t GetTX(void) const { return qTX; }
  uint64_t GetTXpkt(void) const { return qTXp; }
  size_t GetTXQCount(void) const { return plTX.size(); }
  size_t GetTXQCountSafe(void) { return GetXQCountSafe(plTX); }
  double GetPacketTXSafe(Memory &mbD)
    { return GetPacketXSafe(mbD, plTX, stTX); }
  void CompactTXSafe(Memory &mbD) { CompactXSafe(mbD, plTX, stTX); }
  /* ----------------------------------------------------------------------- */
  int SetErrorSafe(const string &strS)
    { const LockGuard lgSocketSync{ mMutex };
      return SetError(strS); }
  int SetErrorStaticSafe(const string &strS, const bool bS=true)
    { const LockGuard lgSocketSync{ mMutex };
      return SetErrorStatic(strS, bS); }
  void PushDataSafe(PacketList &blD, size_t &stX, const char *cpD,
    const size_t stS)
      { const LockGuard lgSocketSync{ mMutex };
        PushData(blD, stX, cpD, stS); }
  void SendSafe(const MemConst &mcPacket)
    { const LockGuard lgSocketSync{ mMutex }; Send(mcPacket); }
  void SendStringSafe(const string &strData)
    { const LockGuard lgSocketSync{ mMutex }; SendString(strData); }
  /* -- Get timers --------------------------------------------------------- */
  const ClkTimePoint GetTConnect(void) const
    { return ClkTimePoint{ cdConnect }; }
  const ClkTimePoint GetTConnected(void) const
    { return ClkTimePoint{ cdConnected }; }
  const ClkTimePoint GetTRead(void) const
    { return ClkTimePoint{ cdRead }; }
  const ClkTimePoint GetTWrite(void) const
    { return ClkTimePoint{ cdWrite }; }
  const ClkTimePoint GetTDisconnect(void) const
    { return ClkTimePoint{ cdDisconnect }; }
  const ClkTimePoint GetTDisconnected(void) const
    { return ClkTimePoint{ cdDisconnected }; }
  /* -- Set a new callback ------------------------------------------------- */
  void SetNewCallback(lua_State*const lS) { LuaEvtInitEx(lS, 1); }
  /* -- Async thread event callback (called by LuaEvtMaster) ------------- */
  void LuaEvtCallbackAsync(const EvtMain::Cell &epData) try
  { // Get reference to string vector and we need three parameters
    // [0]=Pointer to socket class, [1]=Event list id, [2]=Status
    const EvtMain::Params &eParams = epData.vParams;
    // Remove iterator from our events dispatched list if we can
    if(LuaEvtsCheckParams<3>(eParams))
    { // Get the status and warn if we have incorrect number of parameters
      const unsigned int uiStatus = eParams[2].ui;
      // Lua is not paused?
      if(!bLuaPaused)
      { // Push function callback onto stack
        if(LuaRefGetFunc(1))
        { // Push class reference onto stack
          if(LuaRefGetUData())
          { // Push the status code that was fired and if valid?
            LuaUtilPushInt(lsState, uiStatus);
            if(lua_isinteger(lsState, -1))
            { // Call callback
              LuaUtilCallFuncEx(lsState, 2);
              // Clear references and state if this is the last event
              if(uiStatus == SS_STANDBY.FlagGet()) LuaEvtDeInit();
              // Success
              return;
            } // Not a valid integer so debug it
            else SocketLogSafe(LH_ERROR,
              "Invalid integer\n$", LuaUtilGetVarStack(lsState));
          } // Unknown class?
          else SocketLogSafe(LH_ERROR,
            "Invalid class\n$", LuaUtilGetVarStack(lsState));
        } // Unknown function callback?
        else SocketLogSafe(LH_ERROR,
          "Invalid callback\n$", LuaUtilGetVarStack(lsState));
      } // Lua is paused? Log this just to know this event was ignored
      else SocketLogSafe(LH_WARNING,
        "Ignoring event $=$$!", epData.evtCommand, hex, uiStatus);
    } // Not enough parameters so log error
    else SocketLogSafe(LH_ERROR,
      "Not enough event params ($)", eParams.size());
    // Done
    return EventError();
  } // Exception occured? Cleanup and rethrow exception
  catch(const exception&) { EventError(); throw; }
  /* -- Send request to disconnect ----------------------------------------- */
  bool SendDisconnectAndWait(void)
  { // Send disconnect to socket
    SendDisconnect();
    // Have read thread running?
    if(tReader.ThreadIsRunning())
    { // Tell the thread to stop and wait for it. The end of the thread should
      // call FinishDisconnect() already.
      tReader.ThreadDeInit();
      // Success
      return true;
    } // Cleanup the disconnect
    FinishDisconnect();
    // Nothing closed really
    return false;
  }
  /* -- Get connection status ---------------------------------------------- */
  void AddStatus(const SocketFlagsConst &ssNS)
  { // Ignore if this status is already set
    if(FlagIsSet(ssNS)) return;
    // Add status flag and send event to lua event callback
    FlagSet(ssNS);
    // Send as normal if not finishing up
    DispatchEvent(ssNS);
  }
  /* -- Get connection status and update a timestamp ----------------------- */
  void AddStatus(const SocketFlagsConst &ssNS, SafeClkDuration &duDest)
  { // Set the timestamp. We cannot have an atomic<ClkTimePoint> so we have to
    // store the time point as a duration instead. :-(
    duDest = cmHiRes.GetEpochTime();
    // Set the event
    AddStatus(ssNS);
  }
  /* -- Directly convert a socket's send queue to a table ------------------ */
  void ToLuaTable(lua_State*const lS)
  { // Lock access to packet list
    const LockGuard lgSocketSync{ mMutex };
    // Get transferred bytes count and if gt zero and divisble by 2?
    const size_t stCount = GetTXQCount();
    if(stCount > 0 && stCount % 2 == 0)
    { // Create the table, we're creating non-indexed key/value pairs
      LuaUtilPushTable(lS, 0, stCount / 2);
      // Until queue is empty
      for(string strVar; GetTXQCount() > 0;)
      { // Get packet data in send qeue
        Memory mbPacket;
        GetPacket(mbPacket, plTX, stTX);
        // If we haven't set the key name
        if(strVar.empty()) { strVar = mbPacket.MemToString(); continue; }
        // Get value string from packet and store entry
        const string strVal{ mbPacket.MemToString() };
        LuaUtilPushStr(lS, strVal);
        lua_setfield(lS, -2, strVar.c_str());
        // Clear string
        strVar.clear();
      }
    } // Create the empty table
    else LuaUtilPushTable(lS);
  }
  /* -- Send request to disconnect ----------------------------------------- */
  bool SendDisconnect(void)
  { // Ignore if already disconnecting
    if(IsDisconnectingOrDisconnected()) return false;
    // If the connection was closed by the server then it's a clean exit
    SocketLogSafe(LH_DEBUG, "Disconnecting...");
    // Disconnecting
    AddStatus(SS_DISCONNECTING, cdDisconnect);
    // Lock access to packet list
    const LockGuard lgSocketSync{ mMutex };
    // If we have a BIO and there is no fd? (i.e. stuck in BIO_do_connect)
    if(bioPtr && iFd == -1) UpdateDescriptor();
    // If socket is open?
    if(iFd != -1)
    { // Closed by us if not closed by server
      if(FlagIsClear(SS_CLOSEDBYSERVER)) FlagSet(SS_CLOSEDBYCLIENT);
      // Force close the socket to unblock recv()
      // This will probably cause a 'system lib' error as well
      BIO_closesocket(iFd);
      // Fd no longer valid
      iFd = -1;
      // We don't care if an error occured
      ERR_clear_error();
    } // Set thread to exit if we are not calling from it
    if(tReader.ThreadIsNotCurrent() && tReader.ThreadIsRunning())
      tReader.ThreadSetExit();
    // Closing
    return true;
  }
  /* -- Push key value pair ------------------------------------------------ */
  void PushTXPairSafe(const string &strVar, const string &strVal)
  { // Thread safety
    const LockGuard lgSocketSync{ mMutex };
    // Get items and push into TX
    PushData(plTX, stTX, StrToLowCaseRef(UtilToNonConst(strVar)).data(),
      strVar.size());
    PushData(plTX, stTX, strVal.data(), strVal.size());
  }
  /* -- Valid Hostname checker --------------------------------------------- */
  static bool ValidAddress(const string &strA)
  { // Walk and check valid hostname/ip characters until end of string
    return !any_of(strA.cbegin(), strA.cend(), [](const char cChar){
      return !isalpha(static_cast<unsigned char>(cChar)) &&
             !isdigit(static_cast<unsigned char>(cChar)) &&
             cChar != '.' && cChar != '-';
    });
  }
  /* -- Setup Cipher ------------------------------------------------------- */
  void SetupCipher(const string &strC)
  { // Default specified? Use defaults from both cvars
    if(strC == cParent->strCipherDefault)
    { // Setup <=TLSv1.2 ciphers
      strCipherList = cSockets->strvCipher12;
      // Setup TLSv1.3 ciphers
      strCipherSuite = cSockets->strvCipher13;
      // Done
      return;
    } // Split ciphers into two tokens
    const Token tData{ strC, "|" };
    // If we only have one part
    switch(tData.size())
    { // No tokens (insecure connection)
      case 0: strCipherSuite.clear(); strCipherList.clear(); break;
      // Only one token specified?
      case 1:
      { // Set TLSv1.3 cipher suite
        const string &strSuite = tData.front();
        strCipherSuite = strSuite == cParent->strCipherDefault ?
          cSockets->strvCipher13 : strSuite;
        // Set <=TLSv1.2 cipher list
        strCipherList = cSockets->strvCipher12;
        // Done
        break;
      } // Two tokens specified?
      case 2:
      { // Set TLSv1.3 cipher suite
        const string &strSuite = tData.front();
        strCipherSuite = strSuite == cParent->strCipherDefault ?
          cSockets->strvCipher13 : strSuite;
        // Set <= TLSv1.2 cipher list
        const string &strList = tData[1];
        strCipherList = strList == cParent->strCipherDefault ?
          cSockets->strvCipher12 : strList;
        // Done
        break;
      } // Invalid
      default: XC("Only two cipher tokens allowed!",
                  "Address", strAddr,     "Port", uiPort,
                  "Count",   tData.size(),"Spec", strC);
    }
  }
  /* -- Init connection ---------------------------------------------------- */
  void Connect(lua_State*const lS)
  { // Need 5 parameters
    LuaUtilCheckParams(lS, 5);
    // Get and check parameters
    const string strA{ LuaUtilGetCppStrNE(lS, 1, "Address") };
    const unsigned int uiP =
      LuaUtilGetIntLG<unsigned int>(lS, 2, 1, 65535, "Port");
    const string strC{ LuaUtilGetCppStr(lS, 3, "Cipher") };
    LuaUtilCheckFunc(lS, 4, "Callback");
    // Set address and port and TLS cipher
    SetAddress(strA, uiP);
    SetupCipher(strC);
    // Init LUA references
    LuaEvtInitEx(lS);
    // Initialise name, thread and start the connection process
    IdentSetA("S:", GetAddressAndPort());
    tReader.ThreadInit(StrAppend("SR:", GetAddressAndPort()),
      bind(&Socket::SockReadThreadMain, this, _1), this);
  }
  /* -- Init --------------------------------------------------------------- */
  void HTTPRequest(lua_State*const lS)
  { // Need 9 parameters
    LuaUtilCheckParams(lS, 9);
    // Get and check parameters
    const string strC{ LuaUtilGetCppStr(lS, 1, "Cipher") },
                 strA{ LuaUtilGetCppStrNE(lS, 2, "Address") };
    const unsigned int uiP =
      LuaUtilGetIntLG<unsigned int>(lS, 3, 1, 65535, "Port");
    const string strR{ LuaUtilGetCppStrNE(lS, 4, "Request") },
                 strS{ LuaUtilGetCppStrUpper(lS, 5, "Scheme") },
                 strH{ LuaUtilGetCppStr(lS, 6, "Headers") },
                 strB{ LuaUtilGetCppStr(lS, 7, "Body") };
    LuaUtilCheckFunc(lS, 8, "EventFunc");
    // Request must begin with a forward slash
    if(strR.front() != '/') XC("Resource is invalid!", "Resource", strR);
    // Set address and TLS cipher
    SetAddress(strA, uiP);
    SetupCipher(strC);
    // Initialise registry with headers
    pRegistry.ParserReInit(strH, cCommon->Lf(), ':');
    // Push default user agent if not specified already
    pRegistry.ParserPushIfNotExist("user-agent", cSockets->strvUserAgent);
    // Find if the request contains a bookmark fragment
    const size_t stFrag = strR.find('#');
    // Start building registry for connector thread
    pRegistry.ParserPushOrUpdatePairs({
      // Also disable keep-alive, we don't support it (yet?).
      { "connection", "close" },
      // Push the source address
      { "host", StdMove(strA) },
      // Push the formulated request line. Remove the right hand fragment from
      // the URL if neccesary.
      { cParent->strRegVarREQ, StrAppend(strS, ' ',
          (StrUrlEncodeSpaces(stFrag == string::npos ?
            strR : strR.substr(0, stFrag))), " HTTP/1.0\r\n") },
      // Push method because we need to check if this is a HEAD request and
      // thus to know when to expect no output.
      { cParent->strRegVarMETHOD, StdMove(strS) },
    });
    // Body specified?
    if(!strB.empty()) pRegistry.ParserPushOrUpdatePairs({
      // Add length of body text
      { "content-length", StrFromNum(strB.length()) },
      // Add body text
      { cParent->strRegVarBODY, StdMove(strB) }
    });
    // Init LUA references
    LuaEvtInitEx(lS);
    // Start the thread
    IdentSetA("HS:", GetAddressAndPort());
    tReader.ThreadInit(StrAppend("HSR:", GetAddressAndPort()),
      bind(&Socket::SocketHTTPThreadMain, this, _1), this);
  }
  /* -- Constructor -------------------------------------------------------- */
  Socket(void) :
    /* -- Initialisers ----------------------------------------------------- */
    ICHelperSocket{ cSockets, this },  // Register in collector
    IdentCSlave{ cParent->CtrNext() }, // Initialise identification number
    LuaEvtSlave{ this,                 // Socket async events init
      EMC_MP_SOCKET },                 // ...with this id
    SocketFlags{ SS_STANDBY },         // Initially on standby
    bioPtr(nullptr),                   // Invalid bio (openssl)
    sslctxPtr(nullptr),                // Invalid ssl context (openssl)
    sslPtr(nullptr),                   // Invalid ssl (openssl)
    qRX(0), qTX(0),                    // No RX or TX bytes
    qRXp(0), qTXp(0),                  // No RX or TX packets
    tReader{ STP_LOW },                // Low priority reader thread
    tWriter{ STP_LOW },                // Low priority writer thread
    bUnlock(false),                    // Block sock writer thread
    uiPort(0),                         // No port
    iError(0),                         // No error
    iFd(-1),                           // Invalid file descriptor
    stRX(0), stTX(0)                   // No RX or TX packets in queue
    /* --------------------------------------------------------------------- */
    { }
  /* -- Destructor --------------------------------------------------------- */
  ~Socket(void) { SendDisconnectAndWait(); }
  /* ----------------------------------------------------------------------- */
  DELETECOPYCTORS(Socket)              // Supress copy constructor for safety
};/* ----------------------------------------------------------------------- */
/* ------------------------------------------------------------------------- */
static void DestroyAllSockets(void)
{ // No sockets? Ignore
  if(cSockets->empty()) return;
  // Close all connections and report status
  cLog->LogDebugExSafe("Sockets closing all $ connections...",
    cSockets->size());
  cSockets->CollectorDestroyUnsafe();
  cLog->LogInfoExSafe("Sockets closed all connections [$]!",
    cSockets->size());
}
/* ------------------------------------------------------------------------- */
static void DeInitSockets(void)
{ // Deregister event so callbacks cannot fire
  cEvtMain->Unregister(EMC_MP_SOCKET);
  // Close all socket
  DestroyAllSockets();
}
/* ------------------------------------------------------------------------- */
static void InitSockets(void)
{ // The operating systems sockets API needs to be initialised here because
  // we do not want it initialising during connection in other threads as other
  // connections and threads may not wait for initialisation (*cough* Windows)
  // and just fail. This fixes that so the sockets are ready to use on demand.
  // This could be an OpenSSL bug really where they really should be locking
  // other connections when sockets API intiialisation is needed.
  BIO_sock_init();
}
/* ------------------------------------------------------------------------- */
END_COLLECTOREX(Sockets, InitSockets(), DeInitSockets(),,
  /* -- Initialisers ------------------------------------------------------- */
  LuaEvtMaster{ EMC_MP_SOCKET },       // Setup async socket event
  strRegVarREQ{ "\001" },              // Init reg key name for request data
  strRegVarBODY{ "\002" },             // " for http body data
  strRegVarPROTO{ "\003" },            // " for http protocol data
  strRegVarCODE{ "\004" },             // " for http status code data
  strRegVarMETHOD{ "\005" },           // " for http method string
  strRegVarRESPONSE{ "\255" "0" },     // " for http response string
  strCipherDefault{ "-" },             // Default cipher
  qRX(0), qTX(0),                      // Init received and sent bytes
  qRXp(0), qTXp(0),                    // Init received and sent packets
  stConnected(0)                       // Init sockets connected
) /* ======================================================================= */
static size_t SocketWaitAsync(void)
{ // No sockets? Ignore
  if(cSockets->empty()) return 0;
  // Close all sockets. DON'T destroy them!
  cLog->LogDebugExSafe("Sockets waiting to close $ connections...",
    cSockets->size());
  const ssize_t stClosed = count_if(cSockets->begin(), cSockets->end(),
    [](Socket*const sCptr) { return sCptr->SendDisconnectAndWait(); });
  cLog->LogInfoExSafe("Sockets reset $ of $ connections!",
    stClosed, cSockets->size());
  // Return number of connections reset
  return static_cast<size_t>(stClosed);
}
/* ------------------------------------------------------------------------- */
static size_t SocketReset(void)
{ // No sockets? Ignore
  if(cSockets->empty()) return 0;
  // Close all sockets. DON'T destroy them!
  cLog->LogDebugExSafe("Sockets closing $ connections...",
    cSockets->size());
  const ssize_t stClosed = count_if(cSockets->begin(), cSockets->end(),
    [](Socket*const sCptr) { return sCptr->SendDisconnect(); });
  cLog->LogInfoExSafe("Sockets reset $ of $ connections!",
    stClosed, cSockets->size());
  // Return number of connections reset
  return static_cast<size_t>(stClosed);
}
/* -- OCSP options --------------------------------------------------------- */
static CVarReturn SocketOCSPModified(const int iState)
  { return CVarSimpleSetIntNG(cSockets->iOCSP, iState, 2); }
/* -- Return if cvar can be set (accept only 1024-16384 for now) ----------- */
static CVarReturn SocketSetBufferSize(const size_t stSize)
  { return CVarSimpleSetIntNLG(cSockets->stBufferSize,
      stSize, 4096UL, 1048576UL); }
/* ------------------------------------------------------------------------- */
static CVarReturn SocketSetRXTimeout(const double dNew)
  { return CVarSimpleSetIntNLG(cSockets->dRecvTimeout, dNew, 0, 3600); }
/* ------------------------------------------------------------------------- */
static CVarReturn SocketSetTXTimeout(const double dNew)
  { return CVarSimpleSetIntNLG(cSockets->dSendTimeout, dNew, 0, 3600); }
/* ------------------------------------------------------------------------- */
static CVarReturn SocketSetCipher12(const string&, const string &strV)
  { cSockets->strvCipher12 = strV; return ACCEPT; }
/* ------------------------------------------------------------------------- */
static CVarReturn SocketSetCipher13(const string&, const string &strV)
  { cSockets->strvCipher13 = strV; return ACCEPT; }
/* ------------------------------------------------------------------------- */
static CVarReturn SocketAgentModified(const string &strN, string &strV)
{ // Ignore if string too long
  if(strN.size() > 200) return DENY;
  // If empty? We'll set a default value
  if(strN.empty())
    strV = StrFormat("Mozilla/5.0 ($; $-bit; v$.$.$.$) $/$",
      cSystem->ENGName(), cSystem->ENGBits(), cSystem->ENGMajor(),
      cSystem->ENGMinor(), cSystem->ENGBuild(), cSystem->ENGRevision(),
      cSystem->GetGuestShortTitle(), cSystem->GetGuestVersion());
  // Not empty to use user value instead
  else strV = strN;
  // Set string view
  cSockets->strvUserAgent = strV;
  // We changed the value so return that
  return ACCEPT_HANDLED;
}
/* -- Find socket (Lock the mutex before using) ---------------------------- */
static const Sockets::const_iterator SocketFind(const unsigned int uiId)
  { return StdFindIf(par_unseq, cSockets->cbegin(), cSockets->cend(),
      [uiId](const Socket*const sCptr)
        { return sCptr->CtrGet() == uiId; }); }
/* ------------------------------------------------------------------------- */
static StrNCStrMap SocketOAuth11(const string &strMethod,
  const string &strScheme, const string &strHost, const string &strPort,
  const string &strReq, const string &strURLparams, const string &strParams)
{ // Input varlist and split params into it
  Parser<> pParams{ strParams, cCommon->Lf(), '=' };
  if(pParams.empty()) return {};
  // Get consumer key
  const string strCK{ pParams.Extract("oauth_consumer_key") };
  if(strCK.empty())
    XC("No 'oauth_consumer_key' specified!",
       "Method",  strMethod, "Scheme", strScheme,
       "Host",    strHost,   "Port",   strPort,
       "Request", strReq,    "Params", strParams);
  // Get token
  const string strTok{ pParams.Extract("oauth_token") };
  if(strTok.empty())
    XC("No 'oauth_token' specified!",
       "Method",  strMethod, "Scheme", strScheme,
       "Host",    strHost,   "Port",   strPort,
       "Request", strReq,    "Params", strParams);
  // Get user secret
  const string strUS{ pParams.Extract("oauth_user_secret") };
  if(strUS.empty())
    XC("No 'oauth_user_secret' specified!",
       "Method",  strMethod, "Scheme", strScheme,
       "Host",    strHost,   "Port",   strPort,
       "Request", strReq,    "Params", strParams);
  // Get consumer secret
  const string strCS{ pParams.Extract("oauth_consumer_secret") };
  if(strCS.empty())
    XC("No 'oauth_consumer_secret' specified!",
       "Method",  strMethod, "Scheme", strScheme,
       "Host",    strHost,   "Port",   strPort,
       "Request", strReq,    "Params", strParams);
  // If scheme and default port are equal then ignore port
  const string strCPort{ (strScheme == "https" && strPort != "443") ||
    (strScheme == "http" && strPort != "80") ?
      StrAppend(':', strPort) : cCommon->Blank() };
  // Generate full url
  string strAddr{ StrAppend(strScheme, "://", strHost, strCPort, strReq) };
  // Put basic stuff in. Be careful of using StrPair with CStrings as
  // you cant use string& with cstrings, so use CSTR*PAIR's instead.
  StrNCStrMap ssmFinal{{
    { "oauth_consumer_key",                       StdMove(strCK) },
    { "oauth_nonce", SHA1functions::HashMB(CryptRandomBlock(64)) },
    { "oauth_timestamp",              StrFromNum(cmSys.GetTimeS()) },
    { "oauth_token",                             StdMove(strTok) },
    { "oauth_signature_method",                      "HMAC-SHA1" },
    { "oauth_version",                                     "1.0" }
  }};
  // Copy config vars and oauth vars into unsigned params map
  StrNCStrMap ssmDupe{ ssmFinal };
  ssmDupe.insert(pParams.cbegin(), pParams.cend());
  // Split URL parameters and put each one in unsigned parameters list
  const ParserConst<> pUrl{ strURLparams, "&", '=' };
  ssmDupe.insert(pUrl.cbegin(), pUrl.cend());
  // Now for each unsigned parameter. Encode it into the signed param table.
  const string strOAParams{ CryptImplodeMapAndEncode(ssmDupe, "&") };
  // Whats left in pParams should be body parameters so lets sign them
  const string strBody{ CryptImplodeMapAndEncode(pParams, "&") };
  // Hash the string with the key and return empty if fail
  ssmFinal.insert({ "oauth_signature",
    CryptURLEncode(CryptMBtoB64(StdMove(SHA1functions::HashStrRaw(
      StrAppend(CryptURLEncode(strCS), '&', CryptURLEncode(strUS)),
      StrAppend(CryptURLEncode(strMethod), '&', CryptURLEncode(strAddr), '&',
                CryptURLEncode(strOAParams))
  )))) });
  // Build final oauth string
  const string strKV{ ImplodeMap(ssmFinal, ", ") };
  // Whats left in pUrl should be body parameters so lets sign them
  string strURLParams{ CryptImplodeMapAndEncode(pUrl, "&") };
  // This is the URL resource + parameters
  string strResParams{ strReq };
  // Have parameters?
  if(!strURLParams.empty())
  { // Build URL parameters part
    strURLParams = StrAppend('?', strURLParams);
    // Append to request
    strResParams.append(strURLParams);
    // Apend to URL address
    strAddr.append(strURLParams);
  } // Return final result
  return {{ "method",   StdMove(strMethod)         },
          { "url",      StdMove(strAddr)           },
          { "scheme",   StdMove(strScheme)         },
          { "host",     StdMove(strHost)           },
          { "port",     StdMove(strPort)           },
          { "resource", StdMove(strReq)            },
          { "params",   StdMove(strURLParams)      },
          { "request",  StdMove(strResParams)      },
          { "oauth",    StrAppend("OAuth ", strKV) },
          { "body",     StdMove(strBody)           }};
}
/* ------------------------------------------------------------------------- */
}                                      // End of public module namespace
/* ------------------------------------------------------------------------- */
}                                      // End of private module namespace
/* == EoF =========================================================== EoF == */

#Include "TOTVS.CH"
#Include "RESTFUL.CH"
  
WSRESTFUL WSRCLIENTE DESCRIPTION "Consulta se cliente esta ativo base Protheus"

    WSMETHOD GET DESCRIPTION "Consulta se cliente esta ativo base Protheus"  WSSYNTAX "/WSRCLIENTE/"
 
END WSRESTFUL 

WSMETHOD GET WSSERVICE WSRCLIENTE
    Local cUsuario
    Local lRet
    Local cCGC  := ""
    Local cBody   
    Local jReq  := JSonObject():New()
    
    ::SetContentType("application/json")  
    cBody  := ::GetContent()
    If(!Empty(cBody))
        jReq:FromJson(cBody)
        
        cCGC := AllTrim(jReq['CGC'])
        If( cCGC <> Nil .AND. !Empty(cCGC) )
            If GetCliente(cCGC)
                //conout(cRet)
                ::SetResponse('{"Cliente":"'+cCGC+'","Status":"Ativo" }')
             Else
                ::SetStatus(201)
                ::SetResponse(EncodeUTF8('{"Cliente":"'+cCGC+'","Status":"Não Localizado" }'))
            EndIf
         Else
            ::SetStatus(400)
            ::SetResponse(EncodeUTF8('{"message":"Problemas na estrutura da requisição!"}'))
        EndIf
     Else
        ::SetStatus(400)
        ::SetResponse('{"message":"Erro na captura das informacoes, Revise os dados!"}')
    EndIf
return(.T.) 


static Function GetCliente(cCGC)
    
    Local lRet := .F.
   
    dbselectArea("SA1")
	dbGoTop()
    dbSetOrder(3)
    If( SA1->(dbSeek(xFilial("SA1")+cCGC)) )
        lRet := .T.
    EndIf

Return (lRet)

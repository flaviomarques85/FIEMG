#Include "TOTVS.CH"
#Include "RESTFUL.CH"
  
//----------------------------------------------------------------------------- 
/*/{Protheus.doc} 		
          
@author  Flavio Marques 
@since   06/08/2020
@version P12
@type  Funcao
*/
//-----------------------------------------------------------------------------


WSRESTFUL WSRFILIAL DESCRIPTION "Rest de resposta Filiais do sistem"

    WSMETHOD GET DESCRIPTION "resposta para Filiais do sistem"  WSSYNTAX "/WSRFILIAL/"
 
END WSRESTFUL 

WSMETHOD GET WSSERVICE WSRFILIAL

    Local lRet
    Local cRet     //Retorno da pesquisa 
    Local cUsuario:= ""
    Local cBody   //:= cDados
    Local jReq    := JSonObject():New()
    Local jRes    := JSonObject():New()

    ::SetContentType("application/json")  
    cBody  := ::GetContent()
    
    jReq:FromJson(cBody)
    cUsuario := jReq['Usuario']
    PswOrder(1)
    lRet := PswSeek(cUsuario,.T.)

    jRes['Response'] := GetFiliais()
    cRet := jRes:ToJson()
    conout(cRet)
    ::SetResponse(cRet)
  
return(.T.) 



static Function GetFiliais()
    
    Local jFiliais
    Local aRet := {}

    dbselectArea("SM0")
	dbGoTop()
    While !Eof()
        jFiliais:= JsonObject():New()
        jFiliais['CodEmpresa'] := AllTrim(SM0->M0_CODIGO)
        jFiliais['DescEmpresa'] := AllTrim(SM0->M0_NOME)
        jFiliais['CodFilial']  := AllTrim(SM0->M0_CODFIL)
        jFiliais['DescFilial'] := AllTrim(SM0->M0_FILIAL)
        jFiliais['Cnpj'] := AllTrim(SM0->M0_CGC)
        
        AADD(aRet,jFiliais)
        dbSkip()
        FreeObj(jFiliais)
    EndDo
    
Return (aRet)



#Include "TOTVS.CH"
#Include "RESTFUL.CH"
  
WSRESTFUL WSRPRODUTO DESCRIPTION "Rest de lista de prudotos cadastrados"

    WSMETHOD GET DESCRIPTION "Metodo GET para listagem de produtos"  WSSYNTAX "/WSRPRODUTO/"
 
END WSRESTFUL 

WSMETHOD GET WSSERVICE WSRPRODUTO

    Local cRet
    Local cBody   
    Local jReq    := JSonObject():New()
    Local jRes    := JSonObject():New()

    Private cTipo  := ""
    Private cGrupo := ""
    
    ::SetContentType("application/json")  
    cBody  := ::GetContent()
    
    jReq:FromJson(cBody)
    IF jReq['tipo'] <> Nil
        cTipo := jReq['tipo']
    EndIf
    IF jReq['grupo'] <> Nil
        cGrupo := jReq['grupo']
    EndIf
    
    jRes['Response'] := GetProduto()
    cRet := jRes:ToJson()
    ::SetResponse( EncodeUTF8(cRet))
    
return(.T.) 


static Function GetProduto()
    
    Local jProduto
    Local cQuery  := ""
    Local cAliasQry := GetNextAlias()
    Local aRet := {}

    cQuery := " SELECT B1_COD, B1_DESC  "
    cQuery += " FROM  "+RetSqlName("SB1")+" as SB1 "
    cQuery += " WHERE SB1.D_E_L_E_T_ <> '*' "
    cQuery += " AND B1_FILIAL = '"+ xFilial('SB1') +"' "
    cQuery += " AND B1_MSBLQL <> '1'  "
    IF !Empty(cTipo)
        cQuery += " AND B1_TIPO = '"+cTipo+"' "
    EndIf
    IF !Empty(cGrupo)
        cQuery += " AND  B1_GRUPO = '"+cGrupo+"' "
    EndIf
    
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasQry)

    While (cAliasQry)->(!Eof())
        jProduto:= JsonObject():New()
        jProduto['Codigo']    := AllTrim((cAliasQry)->B1_COD)
        jProduto['Descricao'] := AllTrim((cAliasQry)->B1_DESC)
        
        AADD(aRet,jProduto)
        (cAliasQry)->(dbSkip())
        FreeObj(jProduto)
    EndDo
    (cAliasQry)->(dbCloseArea())

Return (aRet)





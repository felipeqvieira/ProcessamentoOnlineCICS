       IDENTIFICATION DIVISION.
       PROGRAM-ID. CADCLI.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-COMMAREA.
           05 LK-FLAG-CONSULTA PIC X(01) VALUE 'N'.
           05 LK-CODCLI-SALVO  PIC 9(06) VALUE ZEROS.

       01  WS-RESPOSTA         PIC S9(08) COMP.

       01  WS-REGISTRO.
           05 REG-CODCLI       PIC 9(06).
           05 REG-NOME         PIC X(30).
           05 REG-TELEFONE     PIC X(15).
           05 REG-CIDADE       PIC X(20).
       01  WS-MENSAGENS.
           05 MSG-ERRO-TECLA   PIC X(30) VALUE 'ERRO: TECLA INVALIDA.'.
           05 MSG-ERRO-COD     PIC X(30) VALUE 'ERRO: CODIGO INVALIDO.'.
           05 MSG-NAO-ENCONT   PIC X(30) VALUE 'CLIENTE NAO ENCONTRADO'.
           05 MSG-ENCONTRADO   PIC X(30) VALUE 'CLIENTE ENCONTRADO.'.
           05 MSG-CONSULTE-PRI PIC X(30) VALUE 'ERRO: CONSULTE ANTES.'.
           05 MSG-ALTERADO     PIC X(30) VALUE 'ALTERACAO REALIZADA.'.

       COPY DFHAID.
       COPY MAPSCA.

       LINKAGE SECTION.
       01  DFHCOMMAREA         PIC X(7).

       PROCEDURE DIVISION.
       0000-PRINCIPAL.
           IF EIBCALEN = 0
               PERFORM 1000-PRIMEIRA-VEZ
               EXEC CICS RETURN
                    TRANSID('CLIE')
                    COMMAREA(WS-COMMAREA)
                    LENGTH(7)
               END-EXEC
           ELSE
               MOVE DFHCOMMAREA TO WS-COMMAREA
               IF EIBAID = DFHPF3
                   EXEC CICS SEND CONTROL ERASE FREEKB END-EXEC
                   EXEC CICS RETURN END-EXEC
               ELSE
                   PERFORM 2000-PROCESSA-TELA
                   EXEC CICS RETURN
                        TRANSID('CLIE')
                        COMMAREA(WS-COMMAREA)
                        LENGTH(7)
                   END-EXEC.

       1000-PRIMEIRA-VEZ.
           MOVE LOW-VALUES TO MAPCLIO.
           EXEC CICS SEND MAP('MAPCLI') MAPSET('MAPSCA') ERASE
           END-EXEC.

       2000-PROCESSA-TELA.
           EXEC CICS RECEIVE MAP('MAPCLI') MAPSET('MAPSCA')
                RESP(WS-RESPOSTA)
           END-EXEC.

           IF WS-RESPOSTA = DFHRESP(MAPFAIL)AND EIBAID NOT= DFHCLEAR
               MOVE MSG-ERRO-TECLA TO MENSAGEMO
               EXEC CICS SEND MAP('MAPCLI') MAPSET('MAPSCA')
               END-EXEC
           ELSE
               IF EIBAID = DFHPF5
                   PERFORM 2100-CONSULTAR
               ELSE
                   IF EIBAID = DFHPF6
                       PERFORM 2200-SALVAR
                   ELSE
                       MOVE MSG-ERRO-TECLA TO MENSAGEMO
                       EXEC CICS SEND MAP('MAPCLI') MAPSET('MAPSCA')
                       END-EXEC.

       2100-CONSULTAR.
           IF CODCLIL = 0 OR CODCLII NOT NUMERIC
               MOVE MSG-ERRO-COD TO MENSAGEMO
               EXEC CICS SEND MAP('MAPCLI') MAPSET('MAPSCA')
               END-EXEC
           ELSE
               EXEC CICS READ DATASET('CLIENTES')
                    INTO(WS-REGISTRO)
                    RIDFLD(CODCLII)
                    RESP(WS-RESPOSTA)
               END-EXEC
               PERFORM 2150-VERIFICA-LEITURA.

       2150-VERIFICA-LEITURA.
           IF WS-RESPOSTA = DFHRESP(NORMAL)
               MOVE REG-NOME TO NOMEO
               MOVE REG-TELEFONE TO TELEFONEO
               MOVE REG-CIDADE TO CIDADEO
               MOVE MSG-ENCONTRADO TO MENSAGEMO
               MOVE 'S' TO LK-FLAG-CONSULTA
               MOVE CODCLII TO LK-CODCLI-SALVO
           ELSE
               MOVE SPACES TO NOMEO
               MOVE SPACES TO TELEFONEO
               MOVE SPACES TO CIDADEO
               MOVE MSG-NAO-ENCONT TO MENSAGEMO
               MOVE 'N' TO LK-FLAG-CONSULTA.

           EXEC CICS SEND MAP('MAPCLI') MAPSET('MAPSCA')
           END-EXEC.
       2200-SALVAR.
           IF LK-FLAG-CONSULTA = 'S'
               PERFORM 2220-VALIDA-SALVAR
           ELSE
               MOVE MSG-CONSULTE-PRI TO MENSAGEMO
               EXEC CICS SEND MAP('MAPCLI') MAPSET('MAPSCA')
               END-EXEC.
       2220-VALIDA-SALVAR.
           IF CODCLIL > 0 AND LK-CODCLI-SALVO NOT = CODCLII
               MOVE MSG-CONSULTE-PRI TO MENSAGEMO
               EXEC CICS SEND MAP('MAPCLI') MAPSET('MAPSCA')
               END-EXEC
           ELSE
               EXEC CICS READ DATASET('CLIENTES')
                    INTO(WS-REGISTRO)
                    RIDFLD(LK-CODCLI-SALVO)
                    UPDATE
                    RESP(WS-RESPOSTA)
               END-EXEC
               PERFORM 2250-VERIFICA-UPDATE.
       2250-VERIFICA-UPDATE.
           IF WS-RESPOSTA = DFHRESP(NORMAL)
               MOVE TELEFONEI TO REG-TELEFONE
               MOVE CIDADEI TO REG-CIDADE
               EXEC CICS REWRITE DATASET('CLIENTES')
                    FROM(WS-REGISTRO)
               END-EXEC
               MOVE MSG-ALTERADO TO MENSAGEMO
           ELSE
               MOVE MSG-NAO-ENCONT TO MENSAGEMO.

           EXEC CICS SEND MAP('MAPCLI') MAPSET('MAPSCA')
           END-EXEC.

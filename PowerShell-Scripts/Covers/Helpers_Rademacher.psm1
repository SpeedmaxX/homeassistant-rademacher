function Set-SpecialCharactersDE($inputstring) {
    <#
    
Character	Unicode Character Number (Decimal)	Unicode Character (Hexadecimal )
ß	0223	00DF
ä	0228	00E4
ö	0246	00F6
ü	0252	00FC
Ä	0196	00C4
Ö	0214	00D6
Ü	0220	00DC
    #>
    $umlauts = @(
        @([char]0x00C4,'Ae'),
        @([char]0x00D6,'Oe'),
        @([char]0x00DC,'Ue'),
        @([char]0x00E4,'ae'),
        @([char]0x00F6,'oe'),
        @([char]0x00FC,'ue'),
        @(' ','_')
    )

    foreach ($umlaut in $umlauts) {
        $inputstring = $inputstring.Replace($umlaut[0].ToString(),$umlaut[1])
    }
    return $inputstring
}
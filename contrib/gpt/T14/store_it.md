# Lockwright — testi per App Store e Google Play (italiano, bozza)

**Lingua:** italiano (it-IT). **Stato:** da rivedere da un madrelingua e da verificare rispetto alle funzionalità realmente disponibili al lancio. **Non è una promessa di prezzo, data o presenza negli store.**

Il titolo locale `Lockwright: Fabbro a chiamata` riprende il senso di «Locksmith on Call». Gli annunci per App Store e Google Play hanno testi distinti per il feedback aptico. Nessun riferimento ad Android o Google Play nei campi App Store; nessun riferimento a iPad o App Store nei campi Google Play.

## Controllo limiti

| Campo | Caratteri | Byte UTF-8 | Limite | Esito |
|---|---:|---:|---:|---|
| `as.it.name` | 29 | 29 | 30 | OK |
| `as.it.subtitle` | 27 | 27 | 30 | OK |
| `as.it.promo` | 155 | 156 | 170 | OK |
| `as.it.keywords` | 90 | 90 | 100 byte | OK |
| `as.it.variant_a` | 116 | 116 | 4000 | OK |
| `as.it.whatsnew` | 135 | 135 | 4000 | OK |
| `gp.it.short` | 79 | 79 | 80 | OK |
| `as.it.description` | 2117 | 2149 | 4000 | OK |
| `gp.it.title` | 29 | 29 | 30 | OK |
| `gp.it.haptics_line` | 211 | 215 | 4000 | OK |
| `gp.it.description` | 2173 | 2206 | 4000 | OK |
| `gp.it.whatsnew` | 135 | 135 | 500 | OK |

## App Store (it-IT)

### Nome

<!-- field: as.it.name max=30 -->
**Lunghezza: 29 caratteri (29 byte UTF-8); limite: 30 caratteri.**

```text
Lockwright: Fabbro a chiamata
```

### Sottotitolo

<!-- field: as.it.subtitle max=30 -->
**Lunghezza: 27 caratteri (27 byte UTF-8); limite: 30 caratteri.**

```text
Serrature tra tatto e suono
```

### Testo promozionale

<!-- field: as.it.promo max=170 -->
**Lunghezza: 155 caratteri (156 byte UTF-8); limite: 170 caratteri.**

```text
Un turno serale da fabbro: un perno fa presa, uno scatta e uno a rocchetto mente. Apri ogni serratura con dita e orecchie. Senza pubblicità, anche offline.
```

### Parole chiave

<!-- field: as.it.keywords max=100 bytes -->
**Lunghezza: 90 caratteri (90 byte UTF-8); limite: 100 byte.**

```text
grimaldello,aptica,rompicapo,perni,cilindro,chiave,lucchetto,officina,meccanica,precisione
```

### Descrizione

<!-- field: as.it.description max=4000 -->
**Lunghezza: 2117 caratteri (2149 byte UTF-8); limite: 4000 caratteri.**

```text
Qualcuno è rimasto fuori dalla propria porta. Il fabbro chiamato sei tu.

Lockwright è un gioco sull'apertura delle serrature attraverso il tatto. Vedi una sezione fotorealistica del meccanismo, ma le informazioni decisive arrivano dai pollici e dalle orecchie. Il pollice sinistro mantiene la tensione, il destro muove il grimaldello. Un perno che fa presa oppone resistenza e gratta. Quando un perno si posiziona correttamente, senti uno scatto breve e secco. Un perno a rocchetto finge di essere a posto. Imparerai a distinguerli.

Cosa fai
• Apri serrature con entrambi i pollici: tensione a sinistra, grimaldello a destra.
• Interpreti ogni perno grazie al feedback aptico, al suono e alla sezione del meccanismo.
• Affronti una serratura dopo l'altra. Tre grimaldelli di riserva nella custodia: è tutto il tuo margine d'errore.
• Spendi le monete guadagnate per acquistare e riparare attrezzi in officina. Un attrezzo nuovo significa un tipo diverso di serratura, non un bonus del +10%.
• Usi la lente da orologiaio quando vuoi confermare con gli occhi ciò che le dita sanno già.
• Giochi «al buio»: lo schermo diventa nero e apri la serratura soltanto attraverso tatto e suono.
• Sblocchi le note della vetrina: brevi storie documentate sulle serrature, dagli antichi congegni di legno alla Grande Esposizione del 1851.

Per tutti
• Il feedback aptico non è mai l'unico segnale. Quello che senti al tatto puoi anche udirlo e vederlo: si gioca bene anche senza vibrazioni, iPad compreso.
• Segni di gesso facoltativi sulla sezione aiutano a leggere lo stato di ogni perno.
• Niente pubblicità, punti energia o account. Funziona offline. Le monete non si comprano con denaro reale.
• Nessuno ti mette fretta. Il cronometro compare solo in una sfida separata, se la scegli.

Una precisazione
Tutte le serrature del gioco sono inventate e senza marchio. I meccanismi sono semplificati apposta per renderli comprensibili. È un gioco, non un corso. Un vero fabbro verifica sempre il diritto del cliente a entrare. Anche tu.

Privacy: il gioco non raccoglie dati. I progressi vengono salvati solo sul tuo dispositivo.
```

### Variante A — facoltativa, NON pubblicare prima della decisione D-06

<!-- field: as.it.variant_a max=4000 -->
**Lunghezza: 116 caratteri (116 byte UTF-8); limite: 4000 caratteri.**

```text
Le prime serrature puoi aprirle senza pagare. Un solo acquisto in-app sblocca il gioco completo. Nessun abbonamento.
```

### Novità (versione 1.0)

<!-- field: as.it.whatsnew max=4000 -->
**Lunghezza: 135 caratteri (135 byte UTF-8); limite: 4000 caratteri.**

```text
Prima versione. Borsa pronta, grimaldelli nella custodia. Se qualcosa stride, scrivici: trovi l'indirizzo nelle impostazioni del gioco.
```

## Google Play (it-IT)

### Titolo Google Play

<!-- field: gp.it.title max=30 -->
**Lunghezza: 29 caratteri (29 byte UTF-8); limite: 30 caratteri.**

```text
Lockwright: Fabbro a chiamata
```

### Descrizione breve Google Play

<!-- field: gp.it.short max=80 -->
**Lunghezza: 79 caratteri (79 byte UTF-8); limite: 80 caratteri.**

```text
Apri serrature inventate a tatto: due pollici, scatti, feedback aptico e suono.
```

### Riga sul feedback aptico, specifica per Google Play

<!-- field: gp.it.haptics_line max=4000 -->
**Lunghezza: 211 caratteri (215 byte UTF-8); limite: 4000 caratteri.**

```text
• Il feedback aptico non è mai l'unico segnale. Quello che senti al tatto puoi anche udirlo e vederlo. Le vibrazioni sono più precise sui telefoni con un buon motore aptico, ma puoi giocare anche disattivandole.
```

### Descrizione completa Google Play

<!-- field: gp.it.description max=4000 -->
**Lunghezza: 2173 caratteri (2206 byte UTF-8); limite: 4000 caratteri.**

```text
Qualcuno è rimasto fuori dalla propria porta. Il fabbro chiamato sei tu.

Lockwright è un gioco sull'apertura delle serrature attraverso il tatto. Vedi una sezione fotorealistica del meccanismo, ma le informazioni decisive arrivano dai pollici e dalle orecchie. Il pollice sinistro mantiene la tensione, il destro muove il grimaldello. Un perno che fa presa oppone resistenza e gratta. Quando un perno si posiziona correttamente, senti uno scatto breve e secco. Un perno a rocchetto finge di essere a posto. Imparerai a distinguerli.

Cosa fai
• Apri serrature con entrambi i pollici: tensione a sinistra, grimaldello a destra.
• Interpreti ogni perno grazie al feedback aptico, al suono e alla sezione del meccanismo.
• Affronti una serratura dopo l'altra. Tre grimaldelli di riserva nella custodia: è tutto il tuo margine d'errore.
• Spendi le monete guadagnate per acquistare e riparare attrezzi in officina. Un attrezzo nuovo significa un tipo diverso di serratura, non un bonus del +10%.
• Usi la lente da orologiaio quando vuoi confermare con gli occhi ciò che le dita sanno già.
• Giochi «al buio»: lo schermo diventa nero e apri la serratura soltanto attraverso tatto e suono.
• Sblocchi le note della vetrina: brevi storie documentate sulle serrature, dagli antichi congegni di legno alla Grande Esposizione del 1851.

Per tutti
• Il feedback aptico non è mai l'unico segnale. Quello che senti al tatto puoi anche udirlo e vederlo. Le vibrazioni sono più precise sui telefoni con un buon motore aptico, ma puoi giocare anche disattivandole.
• Segni di gesso facoltativi sulla sezione aiutano a leggere lo stato di ogni perno.
• Niente pubblicità, punti energia o account. Funziona offline. Le monete non si comprano con denaro reale.
• Nessuno ti mette fretta. Il cronometro compare solo in una sfida separata, se la scegli.

Una precisazione
Tutte le serrature del gioco sono inventate e senza marchio. I meccanismi sono semplificati apposta per renderli comprensibili. È un gioco, non un corso. Un vero fabbro verifica sempre il diritto del cliente a entrare. Anche tu.

Privacy: il gioco non raccoglie dati. I progressi vengono salvati solo sul tuo dispositivo.
```

### Novità Google Play (versione 1.0)

<!-- field: gp.it.whatsnew max=500 -->
**Lunghezza: 135 caratteri (135 byte UTF-8); limite: 500 caratteri.**

```text
Prima versione. Borsa pronta, grimaldelli nella custodia. Se qualcosa stride, scrivici: trovi l'indirizzo nelle impostazioni del gioco.
```

## Note di pubblicazione

- **D-06 resta aperta.** La variante A descrive demo e acquisto unico soltanto come opzione redazionale e non va inserita senza approvazione del modello commerciale.
- La descrizione principale, senza il paragrafo opzionale, evita informazioni su prezzo e data di uscita.
- Le versioni complete con la variante A restano sotto le 4.000 battute: App Store 2235; Google Play 2291.
- Le dichiarazioni su funzionamento offline, privacy, assenza di pubblicità, sfide, vetrina e accessibilità devono essere controllate prima della pubblicazione, come indicato nel testo EN di origine.
- Conteggio per caratteri Unicode; per le parole chiave si applica invece il limite in byte UTF-8.

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<html><head>
<title>Statut Grupy Roboczej Web Hypertext Application Technology</title>
  <link rel="stylesheet" media="all" href="/style/tabbed-pages">
  <link rel="icon" href="/images/icon">
  <style type="text/css" media="screen">
  .translation
{ margin: 0px; border:thin solid #000000; color: #325878; text-align:center; }  
</style>
</head><body>
  <h1>
   <span class="the">The</span>
   <strong class="what">Web Hypertext Application Technology</strong>
   <span class="wg">Working Group</span>
  </h1>
  <ul class="navigation">
   <li><a href="/" rel="home">Home</a></li>
   <li><a href="/news/">News</a></li>
   <li><a href="/demos/">Demos</a></li>
   <li><a href="/specs/">Specyfikacje</a></li>
   <li class="this"><strong>Charter</strong></li>
   <li><a href="/mailing-list">Lista mailingowa</a></li>
  </ul>
			<p class="translation">
			  Dokument ten jest tłumaczeniem, którego angielska wersja znajduje się na stronie <a href="/charter">https://whatwg.org/charter</a>.<br>
			    Tłumaczenie zostało wykonane przez zespół <a href="http://www.t4tw.info">T4TW</a> i <a href="http://www.tlumaczenia-angielski.info">ELTT</a>
			  </p>
  <h2>Statut Grupy Roboczej Web Hypertext Application Technology</h2>

  <h3 id="intro">Wstęp</h3>

  <p id="the-good">Deweloperzy oprogramowania w coraz większym stopniu wykorzystują Internet do zamieszczania swoich aplikacji.  Aplikacje użytkowników są stosowane do pobierania danych od użytkownika z aplikacji serwerowych, zaś technologie opracowane przez W3C - jak na przykład HTML, CSS i DOM - często są wykorzystywane przy tworzeniu interfejsu użytkownika takich aplikacji. W połączeniu z ECMAScript technologie te stanową fundament aplikacji internetowych.</p>

  <p id="the-bad">A jednak wymienione wyżej technologie nie zostały opracowane z myślą o aplikacjach internetowych, a te bardzo często polegają na elementach  niezamierzonych przez ich twórców oraz nieopisanych w pełni przez specyfikacje. Następna generacja aplikacji internetowych doda nowych wymagań wobec środowiska programistycznego - będą to wymagania,  którym powyższe technologie mogą nie sprostać. Nowe technologie rozwijane przez W3C i IETF mogą wnieść wiele dobrego do rozwoju aplikacji internetowych, jednak technologie te są najczęściej projektowane z myślą o zaspokojeniu innych wymagań i biorą pod uwagę aplikacje internetowe  jedynie w stopniu marginalnym. </p>
  <h3 id="deliverables">Dostarczane elementy </h3>

  <p id="address">Celem Grupy Roboczej Web Hypertext Applications
  Technology jest zaspokojenie wymagań jednego, spójnego środowiska programistycznego aplikacji internetowych poprzez stworzenie specyfikacji technicznych, które w założeniu mają być w przyszłości zaimplementowane w przeglądarkach internetowych przeznaczonych dla masowego odbiorcy. </p>

  <p>Przewidujemy dostarczenie następujących elementów:</p>

  <ul id="deliv-list">

   <li id="wf2">Web Forms 2.0: udoskonalenie formularzy w HTML 4.01.</li>

   <li id="wa1">Web Applications 1.0: Opcje  programowania aplikacji w HTML.</li>

   <li id="wc1">Web Controls 1.0: Specyfikacja opisująca mechanizmy tworzenia nowych formatów, które mogą zostać wykorzystane w formularzach internetowych i w technologiach tworzenia  aplikacji internetowych.</li>

   <li id="cssrom">CSS Rendering Object Model: Specyfikacja definiująca dostęp do drzewa wyświetlania (rendering tree) w CSS w taki sposób, aby aplikacje miały dostęp do np. aktywnego zaznaczenia lub zawartości generowanej przez pseudoelementy :before i :after.</li>
  </ul>

  <p id="other">Pozostałe elementy, które chcielibyśmy dostarczyć, mogą okazać się potrzebne w uzupełnieniu innych obszarów wymagań aplikacji internetowych. Przykładowo, możemy zająć się specyfikacją nowych elementów semantycznych, które obsługiwałyby typowe zdarzenia, jak choćby te występujące w handlu elektronicznym, na forach, w dziennikach internetowych i grach. Powyższa lista elementów nie jest zamknięta.</p>

  <p id="back-compat">Wszystkie specyfikacje opracowane przez  grupę roboczą muszą uwzględniać kompatybilność wsteczną i jasno określać rozsądne  strategie przejściowe dla twórców. Muszą także przewidywać obsługę błędów, która zapewni współdziałanie nawet, kiedy przyjdzie się  zmierzyć z dokumentami, które nie są zgodne z zasadami specyfikacji.
    <!-- PROPOSED NEW TEXT

  <p id="back-compat-details">Specifically, "backwards compatibility"
  means that it must be possible to write documents and applications
  using the features described in specifications produced by this
  working group but have those documents and applications degrade
  gracefully in user agents that comply to older specifications. New
  features must either fallback onto older, less powerful but
  functionally equivalent features, or be ignored by legacy user
  agents altogether.</p>

  <p id="market-leader">In addition, it must be possible to write
  extensions to the user agent with most market share in such a way
  that pages written to use the working group's new specifications are
  able to use most of these new features in that user agent without
  requiring users to download plugins.</p>

-->
  </p>

  <h3 id="process">Procedura</h3>

  <p id="list">Uczestnicy grupy roboczej wnoszą swój wkład w naszą pracę za pomocą archiwizowanej publicznie listy dyskusyjnej, do której każdy może się swobodnie zapisać. Członkowie grupy roboczej powinni także odpowiadać na zapytania innych uczestników listy dyskusyjnej. </p>

  <p id="editor">Każdemu dokumentowi przypisany jest jego redaktor. Redaktorzy powinni odzwierciedlać w pisanych przez siebie specyfikacjach konsensualną opinię całej grupy roboczej, jednak tylko do redaktora należy przełamywanie impasów, kiedy grupa robocza nie potrafi dojść do porozumienia w jakiejś kwestii. </p>

  <p id="public">Specyfikacje rozwijane są publicznie, a najnowsza ich wersja jest zawsze dostępna dla wszystkich. Podczas opracowywania grupa może stwierdzić, że dokument osiągnął stan stabilny i wymaga oceny szerszej grupy ludzi. W takiej sytuacji dokument zostaje zarchiwizowany w swojej aktualnej postaci i ogłoszone zostaje wezwanie do komentowania. Szkice robocze powinny na tym etapie zawierać ostrzeżenie informujące czytelników o tym, że dana specyfikacja nie jest jeszcze gotowa do implementacji w celach innych niż eksperymentalne, oraz że implementacja eksperymentalna wersji roboczej nie powinna być dołączana do produktów przeznaczonych dla zwykłego użytkownika. </p>
  <p>Grupa robocza może podjąć decyzję o publikacji stabilnej wersji dokumentu tylko wtedy, gdy zdecydowana większość członków grupy roboczej stwierdzi, że dokument jest już gotowy.</p>
  <p id="implement">Jeśli wersja robocza, która została udostępniona do komentowania nie otrzyma żadnych użytecznych komentarzy, grupa robocza może stwierdzić, że specyfikacja jest gotowa do implementacji w przeglądarkach internetowych (zarówno w typowych komputerach osobistych jak i w sprzęcie z niższej półki) i do dostarczenia jej zwykłym użytkownikom. Na tym etapie dokument jest archiwizowany i ogłoszone zostaje wezwanie do jego implementacji.</p>

  <p id="crec">Aby wersja robocza mogła przejść z etapu &quot;wezwania do implementacji&quot; do etapu rekomendacji muszą istnieć przynajmniej dwie współdziałające ze sobą implementacje każdego z elementów. Na potrzeby tego kryterium zdefiniowane zostają następujące terminy:</p>

  <dl>
   <dt id="feature">element</dt>
   <dd>sekcja lub podsekcja specyfikacji.</dd>
   <dt id="interop">współdziałające</dt>
   <dd>takie, które zaliczyły poszczególne części pakietu testów.</dd>
   <dt id="ua">implementacja</dt>
   <dd>agent użytkownika, który :
     <ol>
     <li id="impl">implementuje element.</li>
     <li id="avail">jest dostępny  (tzn. można go swobodnie ściągnąć z Internetu lub jest powszechnie dostępny przez inny mechanizm sprzedaży).
     Spełnienie tego warunku należy udokumentować.</li>
     <li id="ship">funkcjonuje w spedycji  (tzn. wersje programistyczne, prywatne i nieoficjalne nie są wystarczające).</li>
     <li id="real">nie jest eksperymentalny  (tzn. jest przeznaczony dla szerokiego grona odbiorców i może być powszechnie wykorzystywany).</li>
    </ol>
   </dd>
  </dl>

  <p id="return">Jeżeli uzasadnią to opinie na temat implementacji lub, gdy  okaże się, że implementacje nie współdziałają w wystarczającym stopniu, specyfikacje na etapie wezwania do implementacji powracają do stanu wersji roboczej by można było zająć się poruszonymi kwestiami i przyczynami różnic między implementacjami.</p>

  <h3 id="member">Członkostwo</h3>

  <p id="contributors">Każdy może pomóc poprzez zapisanie się na  <a href="/mailing-list">listę dyskusyjną</a>. Lista osób zapisanych na listę dyskusyjną określana jest terminem <dfn>uczestnicy</dfn>.</p>

  <p id="members">Członkiem grupy można zostać tylko będąc zaproszonym przez innego  członka, który jest reprezentantem producenta  przeglądarki internetowej. Grupa ta, określana terminem <dfn>członkowie</dfn> zapewnia przewodnictwo i doradztwo, zgodnie z opisem w statucie powyżej. Członkami grupy są w chwili obecnej:</p>

  <ul id="member-list">
   <li id="anne">Anne van Kesteren</li>
   <li id="brendan">Brendan Eich</li>
   <li id="dbaron">David Baron</li>
   <li id="hyatt">David Hyatt</li>
   <li id="dean">Dean Edwards</li>
   <li id="howcome">Håkon Wium Lie</li>
   <li id="Hixie">Ian Hickson</li>
   <li id="jst">Johnny Stenback</li>
   <li id="mjs">Maciej Stachowiak</li>
  </ul>

  <address id="ian">
  Pytania należy kierować na listę dyskusyjną lub do <a href="mailto:ian@hixie.ch">Iana Hicksona</a>, który reprezentuje naszą grupę.
  </address>

 </body></html>

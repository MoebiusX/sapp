xquery version "1.0-ml";

module namespace facet = "http://marklogic.com/ftex/pub-count";

declare namespace search = "http://marklogic.com/appservices/search";
declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare function facet:get-values($query) {
  let $experts :=
    if (exists($query)) then
      cts:values(cts:path-reference("expert", "collation=http://marklogic.com/collation/codepoint"), (), (), $query)
    else ()
  return
    cts:values(
      cts:field-reference("author", "collation=http://marklogic.com/collation/codepoint"),
      (),
      ("frequency-order"),
      cts:collection-query("Location")
    )[empty($query) or (. = $experts)]
};

declare function facet:get-key($v) {
  let $f := cts:frequency($v)
  return ">" || (floor(($f - 1) div 10) * 10)
};

declare function facet:parse-structured(
  $query-elem as element(),
  $options as element(search:options)
)
  as cts:query
{
  let $subject := normalize-space(string($query-elem/search:value))[. != '']

  let $keys := ()
  let $counts := map:map()
  let $_ :=
    for $v in facet:get-values(())
    let $key := facet:get-key($v)
    let $keys := xdmp:set($keys, ($keys, $key))
    return map:put($counts, $key, (map:get($counts, $key), $v))
  
  return
  
  if (map:contains($counts, $subject)) then
    cts:path-range-query(
      "expert",
      "=",
      map:get($counts, $subject),
      ("collation=http://marklogic.com/collation/codepoint")
    )
  else
    cts:and-query(())
};

declare function facet:start(
  $constraint as element(search:constraint),
  $query as cts:query?,
  $facet-options as xs:string*,
  $quality-weight as xs:double?,
  $forests as xs:unsignedLong*)
as item()*
{
  let $limit := (10, for $o in $facet-options[starts-with(., "limit=")] return xs:int(substring-after($o, "limit=")))[last()]

  let $keys := ()
  let $counts := map:map()
  let $_ :=
    for $v in facet:get-values($query)
    let $key := facet:get-key($v)
    let $keys := xdmp:set($keys, ($keys, $key))
    return map:put($counts, $key, (map:get($counts, $key), $v))
  for $key in distinct-values($keys)[1 to $limit]
  return
    <search:facet-value name="{$key}" count="{count(map:get($counts, $key))}">{$key}</search:facet-value>
};

declare function facet:finish(
  $start as item()*,
  $constraint as element(search:constraint),
  $query as cts:query?,
  $facet-options as xs:string*,
  $quality-weight as xs:double?,
  $forests as xs:unsignedLong*)
as element(search:facet)
{
  element search:facet {
    attribute name {$constraint/@name},
    attribute type { "custom" },
    $start
  }
};
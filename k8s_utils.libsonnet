
{
  // Adds namespace to a K8s object if needed
  withNamespace(obj, ns)::
    if std.type(obj) != 'object' then obj
    else if !std.objectHas(obj, 'kind') then obj
    else if
      (std.objectHas(obj, 'metadata') && std.objectHas(obj.metadata, 'name')) &&
      (!std.objectHas(obj.metadata, 'namespace'))
    then obj { metadata+: { namespace: ns } }
    else obj,

  // Groups kubernetes objects first by kind then by name, using default fallback values
  groupK8sDeep(objs)::
    std.foldl(
      function(acc, obj)
        local kind = if std.objectHas(obj, 'kind') then obj.kind else 'other';
        local name =
          if std.objectHas(obj, 'metadata') && std.objectHas(obj.metadata, 'name')
          then obj.metadata.name
          else 'unnamed';
        local kindMap = if std.objectHas(acc, kind) then acc[kind] else {};
        acc { [kind]: kindMap { [name]: obj } },
      objs,
      {}
    ),
}

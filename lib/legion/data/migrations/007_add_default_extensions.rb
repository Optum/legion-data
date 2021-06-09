Sequel.migration do
  up do
    lex = from(:extensions).insert(namespace: 'Legion::Extensions::Lex', name: 'lex', exchange: 'lex', uri: 'lex')
    [
      { extension_id: lex, namespace: 'Legion::Extensions::Lex::Runners::Register', name: 'register', queue: 'register', uri: 'register' },
      { extension_id: lex, namespace: 'Legion::Extensions::Lex::Runners::Function', name: 'function', queue: 'function', uri: 'function' },
      { extension_id: lex, namespace: 'Legion::Extensions::Lex::Runners::Runner', name: 'runner', queue: 'runner', uri: 'runner' },
      { extension_id: lex, namespace: 'Legion::Extensions::Lex::Runners::Extension', name: 'extension', queue: 'extension', uri: 'extension' }
    ].each do |row|
      from(:runners).insert row
    end

    lex = from(:extensions).insert(namespace: 'Legion::Extensions::Node', name: 'node', exchange: 'node', uri: 'node')
    [
      { extension_id: lex, namespace: 'Legion::Extensions::Node::Runners::Crypt', name: 'crypt', queue: 'crypt', uri: 'crypt' }
    ].each do |row|
      from(:runners).insert row
    end
  end

  down do
    from(:extensions).where(namespace: 'Legion::Extensions::Lex').delete
    from(:extensions).where(namespace: 'Legion::Extensions::Node').delete
  end
end

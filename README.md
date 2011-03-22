# Mneme

    mneme (n.)  mne·me
       1. Psychology: the retentive basis or basic principle in a mind or organism accounting for memory, persisting effect of memory of past events.
       2. Mythology: the Muse of memory, one of the original three Muses. Cf."Aoede, Melete."

Mneme is an HTTP web-service for recording and identifying previously seen records - aka, duplicate detection. To achieve this goal in a scalable, and zero-maintenance manner, it is implemented via a collection of automatically rotated bloomfilters. By using a collection of bloomfilters, you can customize your false-positive error rate, as well as the amount of time you want your memory to perist (ex: remember all keys for last 6 hours).

To minimize the require memory footprint, mneme does not store the actual key names, instead each specified key is hashed and mapped onto the bloomfilter. For data storage, we use Redis getbit/setbit to efficiently store and retrieve bit-level data for each key. Couple this with Goliath app-server, and you have an out-of-the-box, high-performance, customizable duplicate filter.

## Sample configuration

    # example_config.rb

    config['namespace'] = 'default' # namespace for your app (if you're sharing a redis instance)
    config['periods'] = 3           # number of periods to store data for
    config['length']  = 60          # length of a period in seconds (length = 60, periods = 3.. 180s worth of data)

    config['size']    = 1000        # desired size of the bloomfilter
    config['bits']    = 10          # number of bits allocated per key
    config['hashes']  = 7           # number of times each key will be hashed
    config['seed']    = 30          # seed value for the hash function

To learn more about Bloom filter configuration: [Scalable Datasets: Bloom Filters in Ruby](http://www.igvita.com/2008/12/27/scalable-datasets-bloom-filters-in-ruby/)

## Launching mneme

    $> redis-server
    $> gem install mneme
    $> mneme -p 9000 -sv -c config.rb   # run with -h to see all options

That's it! You now have a mneme web service running on port 9000. Let's try querying and inserting some data:

    $> curl "http://127.0.0.1:9000?key=abcd"
    {"found":[],"missing":["abcd"]}

    # -d creates a POST request with key=abcd, aka insert into filter
    $> curl "http://127.0.0.1:9000?key=abcd" -d' '

    $> curl "http://127.0.0.1:9000?key=abcd"
    {"found":["abcd"],"missing":[]}


## Performance & Memory requirements

 - The speed of storing a new key is: O(number of BF hashes) - aka, O(1)
 - The speed of retrieving a key is: O(number of filters * number of BF hashes) - aka, O(1)

Bloom filter is a space-efficient probabilistic data structure that is used to test whether an element is a member of a set. False positives are possible, but false negatives are not. Because we are using Redis as a backend, in-memory store for the filters, there is some extra overhead. Sample memory requirements:

 - 1.0% error rate for 1M items, 10 bits/item: 2.5 mb
 - 1.0% error rate for 150M items, 10 bits per item: 358.52 mb
 - 0.1% error rate for 150M items, 15 bits per item: 537.33 mb

Ex: If you wanted to store up to 24 hours (with 1 hour = 1 bloom filter) of keys, where each hour can have up to 1M keys, and you are willing to accept a 1.0% error rate, then your memory footprint is: 24 * 2.5mb = 60mb of memory. The footprint will not change after 24 hours, because Mneme will automatically rotate and delete old filters for you!

### License

(MIT License) - Copyright (c) 2011 Ilya Grigorik
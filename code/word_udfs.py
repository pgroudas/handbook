@outputSchema('avg_word_length:double')
def avg_word_length(bag):
    """
    Get the average word length in each search.
    """
    num_chars_total = 0
    num_words_total = 0
    for tpl in bag:
        query = tpl[2]
        words = query.split(' ')
        num_words = len(words)
        num_chars = sum([len(word) for word in words])

        num_words_total += num_words
        num_chars_total += num_chars

    return float(num_chars_total) / float(num_words_total)

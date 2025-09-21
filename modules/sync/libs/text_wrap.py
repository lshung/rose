class TextWrap:
    def __init__(self, **kwargs):
        self.default_configs = {
            "separators": ['/', '-', '_'],
            "width": 68,
            "indent": "    "
        }

        self.update_default_configs(kwargs)

    def update_default_configs(self, configs):
        for key, value in configs.items():
            self.default_configs[key] = value

    def wrap(self, text, **kwargs):
        self.update_single_text_configs(kwargs)

        if len(text) <= self.configs["width"]:
            return [text]

        return self.wrap_text(text)

    def update_single_text_configs(self, configs):
        self.configs = self.default_configs.copy()

        for key, value in configs.items():
            self.configs[key] = value

    def wrap_text(self, text):
        lines = []
        remaining_text = text

        while len(remaining_text) > self.configs["width"]:
            index = self.get_index_of_last_separator_before_width(remaining_text)
            lines.append(remaining_text[:index])
            remaining_text = self.configs["indent"] + remaining_text[index:]

        lines.append(remaining_text)

        return lines

    def get_index_of_last_separator_before_width(self, text):
        index = 0
        line = text[:self.configs["width"]]

        for separator in self.configs["separators"]:
            if separator in line:
                index = max(index, line.rindex(separator))

        if index == 0:
            index = self.configs["width"]

        return index

    def visualize(self, wrapped_lines):
        for line in wrapped_lines:
            spaces = " " * (self.configs["width"] - len(line))
            print(f"|{line}{spaces}|")


if __name__ == "__main__":
    tw = TextWrap(width=38)

    test_strings = [
        "/home/user/very-long-directory-name/another-long-subdirectory/file.txt",
        "/homeuserverylongdirectorynameanotherlongsubdirectoryfile.txt"
    ]

    for test_string in test_strings:
        print(test_string)
        tw.visualize(tw.wrap(test_string))
        print()

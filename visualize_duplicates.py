import re
import operator

row_reg = r"\((?:[0-9]*,[0-9]*,)<([0-9]*),(?:[0-9]*)>,<([0-9]*),(?:[0-9]*)>\)"


class Location():
    def __init__(self, rascal_location):
        self.start, self.end = self.convertRascalLocation(rascal_location)

    def convertRascalLocation(self, rascal_location):
        matches = re.finditer(row_reg, rascal_location)
        for match in matches:
             start = match.group(1)
             end = match.group(2)
        return (start,end)

    def getLoc(self):
        return (int(self.start), int(self.end))

    def __str__(self):
        return "Start: {0}, End: {1}".format(self.start, self.end)

    def __repr__(self):
        return "(Start: {0}; End: {1})".format(self.start, self.end)


class DuplicateClass():

    def __init__(self):
        self.duplicates = {}
        return

    def addDuplicate(self, path, duplicate_loc):
        loc = Location(duplicate_loc)

        if path in self.duplicates.keys():
            self.duplicates[path] = self.duplicates[path] + [loc]
        else:
            self.duplicates[path] = [loc]

    def getDups(self):
        return self.duplicates

    def __str__(self):
        str_format = ""
        for k in self.duplicates.keys():
            str_format += "{0} {1}".format(k, self.duplicates[k])
        return str_format


def convertRascalToDups(path):
    f = open(path, 'r')
    regex = r"\|(\w*\+\w*)(?:\:\/\/\/|\/\))([\w(-|_)\/]*)\|(\([0-9]*,[0-9]*,<[0-9]*,[0-9]*>,<[0-9]*,[0-9]*>\))"
    duplist = []
    dupfiles = {}
    for p in f.readlines():
        dups = DuplicateClass()
        matches = re.finditer(regex, p)
        for match in matches:
            path = "" + match.group(2)
            if path not in dupfiles.keys():
                dupfiles[path] = 1
            else:
                dupfiles[path] += 1
            rascalLocation = match.group(3)
            dups.addDuplicate(path, rascalLocation)
        duplist.append(dups)
        files = sorted(dupfiles, key=dupfiles.get)

    return (dupfiles, duplist)

if __name__ == '__main__':
    duplist = convertRascalToDups('TestProject/blader.tmp')
    for dup in duplist:
        print dup

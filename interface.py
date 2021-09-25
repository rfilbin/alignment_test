import requests
from os import getcwd
import json


class ClickUpTask(object):
    def __init__(self) -> None:
        super().__init__()
        self.id = ''
        self.name = ''


class ClickUpTeam(object):
    def __init__(self, team_id) -> None:
        super().__init__()
        self.team_id = team_id
        self.folders = None
        self.lists = []
        self.tasks = []
        self.headers = {
            'Authorization': 'pk_4370546_1BNSFQPZ5SJZS49DJO5MRXWT40RGFIOK'
        }

    def output_json(self, name, payload):
        file = open(getcwd() + '/test_run___' + name + '_output.json', 'w')
        file.write(json.dumps(payload))
        file.close()
        return self

    def retrieve_folders(self):
        response = requests.get('https://api.clickup.com/api/v2/space/' +
                                rambi_id + '/folder?archived=false', headers=self.headers)

        self.folders = response.json()['folders']

        return self

    def retrieve_lists(self):
        for folder in self.folders:
            print(folder['name'] + ' - ')
            response = requests.get(
                'https://api.clickup.com/api/v2/folder/' + folder['id'] + '/list?archived=false', headers=self.headers)

            self.output_json('lists', response.json()['lists'])

            for listItem in response.json()['lists']:
                self.lists.append(listItem)
                print(folder['name'] + ' - ' +
                      listItem['id'] + ' - ' + listItem['name'])

        return self

    def retrieve_tasks(self):
        for listItem in self.lists:
            print(listItem['name'] + ' - ')
            response = requests.get(
                'https://api.clickup.com/api/v2/list/' + listItem['id'] + '/task?archived=false&date_updated_gt=', headers=self.headers)

            self.output_json('tasks', response.json()['tasks'])

            for task in response.json()['tasks']:
                self.tasks.append(task)
                print(listItem['id'] + ' - ' + listItem['name'] +
                      ' - ' + task['id'] + ' - ' + task['name'])

        return self


rambi_id = '10692929'
yoshi_id = '12621394'

teamRambi = ClickUpTeam(rambi_id)
teamRambi.retrieve_folders()
teamRambi.retrieve_lists()
teamRambi.retrieve_tasks()


# teamsResponse = requests.get(
#     'https://api.clickup.com/api/v2/team', headers=headers)


# rambiResponse = requests.get('https://api.clickup.com/api/v2/space/' +
#                              rambi_id + '/folder?archived=false', headers=headers)

# rambiResponseJson = rambiResponse.json()

# for folder in rambiResponseJson['folders']:
#     print(folder['id'])
#     print(folder['name'])
#     listsResponse = requests.get(
#         'https://api.clickup.com/api/v2/folder/' + folder['id'] + '/list?archived=false', headers=headers)

#     for listItem in listsResponse.json()['lists']:

#         tasksResponse = requests.get(
#             'https://api.clickup.com/api/v2/list/' + listItem['id'] + '/task?archived=false&date_updated_gt=', headers=headers)

#         for task in tasksResponse.json()['tasks']:
#             print(folder['name'] + ' - ' + listItem['name'] +
#                   ' - ' + task['id'] + ' - ' + task['name'])

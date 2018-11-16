#!/usr/bin/python

import web
import os

# Get path of the current dir, then use it as working directory:
rundir = os.path.dirname(__file__)
if rundir != '':
    os.chdir(rundir)

filmfolder = '/home/pi/Videos'

# Link video directory to static dir
if os.path.isfile('static/Videos') == False:
    os.system("ln -s -t static/ " + filmfolder)

films = []

urls = (
    '/', 'index',
    '/f/(.*)', 'films'
)

render = web.template.render('templates/', base="base")

class index:
    def GET(self):
        films = os.walk('static/Videos/').next()[1]
        renderedfilms = []
        unrenderedfilms = []
        for i in films:
            if os.path.isfile('static/Videos/' + i + '/' + i + '.mp4') == True:
                renderedfilms.append(i)
            else:
                unrenderedfilms.append(i)
        return render.index(renderedfilms, unrenderedfilms)

class films:
    def GET(self, film):
        return render.filmpage(film)

app = web.application(urls, globals(), autoreload=False)
application = app.wsgifunc()

#if __name__== "__main__":
    #app = web.application(urls, globals())
    #app.run()


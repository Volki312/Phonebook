import './main.css';
import { Elm } from './Main.elm';
import registerServiceWorker from './registerServiceWorker';

Elm.Main.init({
    node: document.getElementById('root'),
    flags: "https://simplephonebook.herokuapp.com/contacts/"
    //flags: "http://localhost:9000/contacts/"

});

registerServiceWorker();

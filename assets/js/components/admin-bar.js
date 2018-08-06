import React from 'react';
import { connect } from 'react-redux';
import { render } from 'react-dom';


class AdminBar extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      selectedUser: null
    };
    this.onSelectUser = this.onSelectUser.bind(this);
    this.onImpersonateUser = this.onImpersonateUser.bind(this);
  }

  onSelectUser(evt) {
    this.setState({selectedUser: evt.target.value});
  }

  onImpersonateUser(evt) {
    evt.preventDefault();
    this.props.dispatch(this.props.impersonateUser(this.state.selectedUser));
  }

  render() {
    const impersonableUsers = this.props.impersonableUsers;
    const isAdmin = this.props.isAdmin;
    const children = this.props.children;

    return (
      <div className="">
        <select className="qa-admin-impersonate-user" onChange={this.onSelectUser}>
          {impersonableUsers.map((user) =>
            <option key={user.id} value={user.id}>{`${user.first_name} ${user.last_name} (${user.company_name})`}</option>
          )}
        </select>
        <button className='qa-admin-impersonate-user-submit' onClick={this.onImpersonateUser} disabled={!this.state.selectedUser}> {'-->'} </button>
        {children}
      </div>
    );
  }
};

export default connect()(AdminBar);

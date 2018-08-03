import React from 'react';

const AdminBar = ({isAdmin, impersonableUsers, children}) => {
  return(
  <div className="">
    <select className="qa-admin-impersonate-user">
    {impersonableUsers.map((user) =>
                           <option key={user.id} value={user.id}>{`${user.first_name} ${user.last_name}`}</option>
                          )}
    </select>
      {children}
  </div>
  );
};
export default AdminBar;

import React from 'react';

const AdminBar = ({isAdmin, impersonableUsers, children, impersonateUser}) => {
  const onImpersonateUser = impersonateUser;

  return(
  <div className="">
    <select className="qa-admin-impersonate-user">
    {impersonableUsers.map((user) =>
                           <option key={user.id} value={user.id}>{`${user.first_name} ${user.last_name} (${user.company_name})`}</option>
                          )}
    </select>
      <button className='qa-admin-impersonate-user-submit'> {'<-'} </button>
      {children}
  </div>
  );
};
export default AdminBar;
